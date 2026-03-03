const { prisma } = require("../utils/prisma");

// สร้าง Report ใหม่ และบันทึกประวัติสถานะแรก (FILED)
const createReportCase = async (data) => {
  const { reporterId, driverId, bookingId, routeId, category, description } = data;

  return prisma.reportCase.create({
    data: {
      reporterId,
      driverId,
      bookingId,
      routeId,
      category,
      description,
      status: 'FILED',
      statusHistory: {
        create: {
          toStatus: 'FILED',
          changedById: reporterId,
          note: 'Initial report filed'
        }
      }
    },
    include: { reporter: true, driver: true }
  });
};

// ดึงรายการ Report ทั้งหมด (สามารถใส่เงื่อนไข filter และ order ได้)
const getReports = async (where = {}, orderBy = { createdAt: "desc" }) => {
  return prisma.reportCase.findMany({
    where,
    include: {
      reporter: { select: { id: true, username: true, email: true, firstName: true, lastName: true } },
      driver: { select: { id: true, username: true, email: true, firstName: true, lastName: true } },
      booking: true,
      route: true,
    },
    orderBy
  });
};

// ดึงรายละเอียด Report รายเคส พร้อมประวัติสถานะและหลักฐาน
const getReportById = async (id) => {
  return prisma.reportCase.findUnique({
    where: { id },
    include: {
      reporter: {
        select: { id: true, username: true, email: true, firstName: true, lastName: true }
      },
      driver: {
        select: {
          id: true,
          username: true,
          email: true,
          firstName: true,
          lastName: true,
          yellowCardCount: true,
          yellowCardExpiresAt: true,
          driverSuspendedUntil: true,
          passengerSuspendedUntil: true,
          isActive: true
        }
      },
      booking: true,
      route: {
        include: {
          bookings: {
            include: {
              passenger: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  yellowCardCount: true,
                  yellowCardExpiresAt: true,
                  driverSuspendedUntil: true,
                  passengerSuspendedUntil: true
                }
              }
            }
          }
        }
      },
      resolvedBy: {
        select: { id: true, firstName: true, lastName: true }
      },
      evidences: true,
      statusHistory: {
        include: { changedBy: { select: { id: true, username: true } } },
        orderBy: { createdAt: "desc" }
      }
    }
  });
};

// อัปเดตสถานะ Report, บันทึกประวัติ, และจัดการระบบใบเหลือง/ใบแดงอัตโนมัติ
const updateReportStatus = async (id, payload) => {
  return prisma.$transaction(async (tx) => {

    const currentReport = await tx.reportCase.findUnique({
      where: { id }
    });

    if (!currentReport) return null;

    const updateData = {
      status: payload.status,
      adminNotes: payload.adminNotes ?? currentReport.adminNotes,
    };

    if (payload.status === 'RESOLVED' || payload.status === 'REJECTED') {
      updateData.resolvedById = payload.resolvedById;
      updateData.resolvedAt = new Date();
    }

    if (payload.status === 'CLOSED') {
      updateData.closedAt = new Date();
    }

    const updatedReport = await tx.reportCase.update({
      where: { id },
      data: updateData
    });

    await tx.reportCaseStatusHistory.create({
      data: {
        reportCaseId: id,
        fromStatus: currentReport.status,
        toStatus: payload.status,
        changedById: payload.resolvedById,
        note: payload.note || `Status updated to ${payload.status}`
      }
    });

    // แจกใบเหลือง
    if (payload.status === 'RESOLVED') {
      await handleYellowCard(tx, currentReport.driverId);
    }

    return updatedReport;
  });
};

// จัดการใบเหลือง
const handleYellowCard = async (tx, userId) => {

  const user = await tx.user.findUnique({
    where: { id: userId }
  });

  if (!user) return;

  const now = new Date();
  let currentCards = user.yellowCardCount || 0;

  // ถ้าหมดรอบ 30 วัน -> เริ่มใหม่
  if (!user.yellowCardExpiresAt || user.yellowCardExpiresAt < now) {
    currentCards = 0;
  }

  currentCards += 1;

  // ครบ 3 ใบใน 30 วัน -> แบน 30 วัน
  if (currentCards >= 3) {

    const suspendUntil = new Date();
    suspendUntil.setDate(suspendUntil.getDate() + 30);

    await tx.user.update({
      where: { id: userId },
      data: {
        yellowCardCount: 0,
        yellowCardExpiresAt: null,
        ...(user.role === 'DRIVER'
          ? { driverSuspendedUntil: suspendUntil }
          : { passengerSuspendedUntil: suspendUntil })
      }
    });

  } else {

    // ยังไม่ครบ 3 ใบ ในรอบ 30 วัน
    const newWindow = new Date();
    newWindow.setDate(newWindow.getDate() + 30);

    await tx.user.update({
      where: { id: userId },
      data: {
        yellowCardCount: currentCards,
        yellowCardExpiresAt: newWindow
      }
    });

  }
};

// แนบหลักฐานหลายไฟล์ลงในเคส Report
const addEvidencesToReport = async (reportCaseId, evidencesData, uploadedById) => {
  const formattedData = evidencesData.map(evidence => ({
    reportCaseId,
    type: evidence.type,
    url: evidence.url,
    fileName: evidence.fileName,
    mimeType: evidence.mimeType,
    fileSize: evidence.fileSize,
    uploadedById
  }));

  return prisma.reportEvidence.createMany({
    data: formattedData
  });
};

module.exports = {
  createReportCase,
  getReports,
  getReportById,
  updateReportStatus,
  addEvidencesToReport
};