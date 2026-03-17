*** Settings ***
Library         SeleniumLibrary
Library         OperatingSystem
Test Teardown   Close Browser

*** Variables ***
${CHROME_DRIVER_PATH}       C:${/}Program Files${/}ChromeForTesting${/}chromedriver-win64${/}chromedriver.exe
${CHROME_BROWSER_PATH}      C:${/}Program Files${/}ChromeForTesting${/}chrome-win64${/}chrome.exe

${BASE_URL}                 https://csse1469.cpkku.com/
${ADMIN_USER}               admin@example.com
${ADMIN_PASS}               123456789
${TEST_USER}                tester1@ex.com
${TEST_PASS}                123456789

*** Test Cases ***

TC-001 Driver Creates 3 Incident Reports
    [Documentation]    ผู้ขับขี่สร้างการแจ้งเหตุ 3 รายการเพื่อใช้ทดสอบ
    Open Chrome Browser Incognito
    Go To Login Page
    Login As User
    Navigate To My Route Page
    # สร้างรายการที่ 1
    Post Incident Report    ACCIDENT    รายการทดสอบที่ 1: อุบัติเหตุทางถนน
    # สร้างรายการที่ 2
    Post Incident Report    VEHICLE_BREAKDOWN    รายการทดสอบที่ 2: รถเสียขัดข้อง
    # สร้างรายการที่ 3
    Post Incident Report    OTHER    รายการทดสอบที่ 3: อื่นๆ
    Verify Driver Status    รอดำเนินการ

TC-002 Admin Resolve Incident
    [Documentation]    แอดมินเลือกเคส Pending -> รับเรื่อง -> จัดการเคส -> กรอกหมายเหตุ -> กดปุ่มดำเนินการเคส
    Open Chrome Browser Incognito
    Go To Login Page
    Login As Admin And Go Dashboard
    Go To Incident Management
    # ขั้นตอนการขอรับเรื่องและ Resolve
    Admin Select Pending Case And Accept
    # ส่ง Arguments: (ชื่อปุ่มที่จะกด, ข้อความใน Note, ข้อความ Noti ที่คาดหวัง, สถานะใหม่ที่คาดหวัง)
    Admin Fill Note And Process Case    ดำเนินการเคส    ดำเนินการช่วยเหลือและแก้ไขเรียบร้อยแล้ว    RESOLVED

TC-003 Admin Reject Incident
    [Documentation]    แอดมินเลือกเคส Pending -> รับเรื่อง -> จัดการเคส -> กรอกหมายเหตุ -> กดปุ่มปฏิเสธเคส
    Open Chrome Browser Incognito
    Go To Login Page
    Login As Admin And Go Dashboard
    Go To Incident Management
    # ขั้นตอนการขอรับเรื่องและ Reject
    Admin Select Pending Case And Accept
    # ส่ง Arguments: (ชื่อปุ่มที่จะกด, ข้อความใน Note, ข้อความ Noti ที่คาดหวัง, สถานะใหม่ที่คาดหวัง)
    Admin Fill Note And Process Case    ปฏิเสธเคส    ข้อมูลไม่เพียงพอในการตรวจสอบ    REJECTED

TC-004 Driver Cancel Incident
    [Documentation]    ผู้ขับขี่สร้างการแจ้งเหตุใหม่ 1 รายการ แล้วทำการกดยกเลิกด้วยตัวเอง
    Open Chrome Browser Incognito
    Go To Login Page
    Login As User
    Navigate To My Route Page
    
    # 1. สร้างเคสใหม่ 1 เคสเตรียมไว้สำหรับยกเลิก
    Post Incident Report    ACCIDENT    รายการทดสอบยกเลิก: รถชนป้ายจราจร
    
    # 2. ทำการกดยกเลิก เช็คข้อความ และยืนยัน Alert
    Driver Cancels The Incident Report    อุบัติเหตุทางถนน    รายการทดสอบยกเลิก: รถชนป้ายจราจร
    
*** Keywords ***

Open Chrome Browser Incognito
    ${opts}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
    ${opts.binary_location}=    Set Variable    ${CHROME_BROWSER_PATH}
    Call Method    ${opts}    add_argument    --incognito
    Call Method    ${opts}    add_argument    --start-maximized
    ${svc}=     Evaluate    sys.modules["selenium.webdriver.chrome.service"].Service(executable_path=r"${CHROME_DRIVER_PATH}")
    Create Webdriver    Chrome    options=${opts}    service=${svc}
    Set Selenium Speed    0.3s

Go To Login Page
    Go To    ${BASE_URL}
    Wait Until Element Is Visible    xpath=//a[@href='/login']    10s
    Click Element    xpath=//a[@href='/login']

Login As User
    Wait Until Element Is Visible    id=identifier    10s
    Input Text        id=identifier    ${TEST_USER}
    Input Password    id=password      ${TEST_PASS}
    Click Button      xpath=//form[@id='loginForm']//button[@type='submit']
    Wait Until Page Contains Element    xpath=//div[contains(@class,'dropdown-trigger')]    15s

Login As Admin And Go Dashboard
    Wait Until Element Is Visible    id=identifier    10s
    Input Text        id=identifier    ${ADMIN_USER}
    Input Password    id=password      ${ADMIN_PASS}
    Click Button      xpath=//form[@id='loginForm']//button[@type='submit']
    Wait Until Element Is Visible    xpath=//div[contains(@class,'dropdown-trigger')]    15s
    # เข้าหน้า Admin Dashboard
    Go To    ${BASE_URL}admin/users
    Wait Until Location Contains    /admin    10s

Navigate To My Route Page
    Wait Until Element Is Visible    xpath=//a[contains(.,'การเดินทางทั้งหมด')]    10s
    Click Element    xpath=//a[contains(.,'การเดินทางทั้งหมด')]
    Wait Until Element Is Visible    xpath=//a[contains(@href, '/myRoute')]    10s
    Click Element    xpath=//a[contains(@href, '/myRoute')]
    Wait Until Element Is Visible    xpath=//button[contains(normalize-space(),'เส้นทางของฉัน')]    10s
    Click Element    xpath=//button[contains(normalize-space(),'เส้นทางของฉัน')]

Post Incident Report
    [Arguments]    ${type}    ${detail}
    Wait Until Element Is Visible    xpath=//button[contains(.,'แจ้งอุบัติเหตุ')]    10s
    Click Element    xpath=//button[contains(.,'แจ้งอุบัติเหตุ')]
    Wait Until Element Is Visible    xpath=//select    10s
    Select From List By Value    xpath=//select    ${type}
    Input Text    xpath=//textarea    ${detail}
    Click Button    xpath=//button[contains(.,'ยืนยันการแจ้งเหตุ')]
    Wait Until Page Contains    แจ้งเหตุฉุกเฉินสำเร็จ    15s
    Sleep    1s    # พักเพื่อให้ UI อัปเดตหลังจากปิด Modal

Verify Driver Status
    [Arguments]    ${status_text}
    Wait Until Element Is Visible    xpath=//button[contains(.,'${status_text}')]    10s
    Page Should Contain    ${status_text}

Go To Incident Management
    Wait Until Element Is Visible    xpath=//span[contains(text(),'Incidents Management')]    10s
    Click Element    xpath=//span[contains(text(),'Incidents Management')]
    Wait Until Location Contains    /admin/incidents    15s

Admin Select Pending Case And Accept
    [Documentation]    กดดูเคส Pending -> กดรับเรื่อง -> เช็ค Noti รับเรื่องเรียบร้อย
    # หาแถว Pending และกด ดูรายละเอียด
    Wait Until Element Is Visible    xpath=//tr[contains(.,'Pending')]    15s
    Click Element    xpath=//tr[contains(.,'Pending')][1]//button[@title='ดูรายละเอียด']
    
    # กดปุ่ม "รับเรื่อง" สีเขียวที่อยู่ด้านนอก
    Wait Until Element Is Visible    xpath=//button[contains(@class,'bg-green-600') and contains(.,'รับเรื่อง')]    10s
    Click Button                    xpath=//button[contains(@class,'bg-green-600') and contains(.,'รับเรื่อง')]
    
    # ตรวจสอบ Notification และสถานะที่เปลี่ยนเป็น กำลังตรวจสอบ
    Wait Until Page Contains    รับเรื่องเรียบร้อย    10s

Admin Fill Note And Process Case
    [Arguments]    ${button_name}    ${note_text}    ${expected_noti}  
    [Documentation]    กดจัดการเคส -> กรอก Note -> กดปุ่มดำเนินการ/ปฏิเสธ -> เช็ค Notification เฉพาะของปุ่มนั้น
    
    # กรอกหมายเหตุ
    Wait Until Element Is Visible    xpath=//textarea    10s
    Input Text                      xpath=//textarea    ${note_text}
    
    # ตรวจสอบและกดปุ่ม (ดำเนินการเคส หรือ ปฏิเสธเคส)
    Wait Until Element Is Enabled    xpath=//button[contains(.,'${button_name}')]    10s
    Click Button                    xpath=//button[contains(.,'${button_name}')]
    
    # ตรวจสอบ Notification ตามที่ได้รับแจ้ง (ดำเนินการเคสเรียบร้อยแล้ว / ปฏิเสธเคสเรียบร้อย)
    Wait Until Page Contains         ${expected_noti}    15s
    


Driver Cancels The Incident Report
    [Arguments]    ${expected_category_text}    ${expected_detail_text}
    [Documentation]    ทำขั้นตอนกดยกเลิกตามรูปที่ 1 และจัดการ Browser Alert ตามรูปที่ 2
    
    # 1. กดปุ่ม "ยกเลิกการแจ้งเหตุ (1)" (ใช้ contains เผื่อตัวเลขในวงเล็บเปลี่ยน)
    Wait Until Element Is Visible    xpath=//button[contains(.,'ยกเลิกการแจ้งเหตุ')]    10s
    Click Element    xpath=//button[contains(.,'ยกเลิกการแจ้งเหตุ')]
    
    # 2. ตรวจสอบว่า Modal ตามรูปที่ 1 เปิดขึ้นมา และมีข้อความตรงกับเคสที่เพิ่งสร้าง
    Wait Until Element Is Visible    xpath=//div[contains(.,'รายการแจ้งอุบัติเหตุที่กำลังดำเนินการ')]    10s
    Wait Until Page Contains    ${expected_category_text}    5s
    Wait Until Page Contains    ${expected_detail_text}      5s
    
    # 3. กดปุ่ม "ยกเลิกเคสนี้" ตัวหนังสือสีแดง
    Wait Until Element Is Visible    xpath=//button[contains(.,'ยกเลิกเคสนี้')]    10s
    Click Element    xpath=//button[contains(.,'ยกเลิกเคสนี้')]
    
    # 4. จัดการ Browser Alert ตามรูปที่ 2 (กดยืนยัน 'ตกลง')
    # คำสั่งนี้จะรอให้ Alert เด้งขึ้นมา เช็คข้อความว่าตรงไหม แล้วกด OK ให้อัตโนมัติ
    Alert Should Be Present    text=คุณต้องการยกเลิกการแจ้งอุบัติเหตุนี้ใช่หรือไม่?    action=ACCEPT    timeout=10s
    
    # 5. ตรวจสอบ Notification บนจอว่าสำเร็จ
    Wait Until Page Contains    ยกเลิกการแจ้งเหตุเรียบร้อยแล้ว    15s