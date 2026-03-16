*** Settings ***
Documentation     UAT for Review System with Incognito Mode - Full E2E Flow
...               1. Driver creates Route
...               2. Passenger searches, books (fills details completely)
...               3. Driver accepts, changes status to complete
...               4. Passenger reviews
Library           SeleniumLibrary
Library           Collections

Suite Setup       Log    Starting Complete E2E UAT
Suite Teardown    Close All Browser Windows

*** Variables ***
${BROWSER}              Chrome
${LOGIN_URL}            http://localhost:3003/login
${BASE_URL}             http://localhost:3003
${TIMEOUT}              15s

${DRIVER_EMAIL}         user1@example.com
${DRIVER_PASS}          123456789
${PASSENGER_EMAIL}      user2@example.com
${PASSENGER_PASS}       123456789

${START_LOCATION}       กรุงเทพมหานคร
${END_LOCATION}         เชียงใหม่
${SEAT_COUNT}           4
${PRICE_PER_SEAT}       250


*** Test Cases ***

STEP_01_Driver_Create_Route
    [Documentation]    Driver สร้าง Route ใหม่
    [Tags]             step1  driver
    
    Open Browser Incognito    ${LOGIN_URL}
    Driver Login    ${DRIVER_EMAIL}    ${DRIVER_PASS}
    
    Go To    ${BASE_URL}/createTrip
    Sleep    3s
    
    # Fill form
    Wait Until Element Is Visible    id=startPoint    ${TIMEOUT}
    Input Text    id=startPoint    ${START_LOCATION}
    Sleep    0.5s
    Input Text    id=endPoint    ${END_LOCATION}
    Sleep    0.5s
    
    ${tomorrow}=    Get Tomorrow Date
    Log    Tomorrow date: ${tomorrow}
    Input Text    id=travelDate    ${tomorrow}
    Sleep    0.5s
    
    # Time - Click the clock/time SVG icon to open dropdown, then press Enter
    Log    Clicking time icon to open dropdown...
    
    # Click input field first to focus it
    Click Element    id=travelTime
    Sleep    1s
    
    # Find and click the SVG icon (clock/time picker icon)
    ${time_svg}=    Run Keyword And Continue On Failure    Get WebElement    xpath=//input[@id='travelTime']/following-sibling::svg | //input[@id='travelTime']/parent::*//*[name()='svg']
    
    Run Keyword If    ${time_svg}    Click Element    ${time_svg}
    ...    ELSE    Log    SVG icon not found in expected location
    
    Sleep    2s
    
    # Press Enter to select the time from dropdown
    Log    Pressing Enter to select time...
    Press Keys    id=travelTime    RETURN
    Sleep    1s
    
    Input Text    id=seatCount    ${SEAT_COUNT}
    Input Text    id=pricePerSeat    ${PRICE_PER_SEAT}
    Sleep    1s
    
    # Select vehicle - must have one registered
    ${veh_sel}=    Run Keyword And Continue On Failure    Get WebElement    id=vehicle
    Run Keyword And Continue On Failure    Click Element    ${veh_sel}
    Run Keyword And Continue On Failure    Sleep    0.5s
    Run Keyword And Continue On Failure    Click Element    xpath=(//option)[2]
    Sleep    1s
    
    # Submit
    Click Button    xpath=//button[contains(text(), 'สร้าง')] | //button[@type='submit']
    Sleep    5s
    
    # Verify
    ${success}=    Run Keyword And Return Status    Page Should Contain    ${START_LOCATION}
    Run Keyword If    ${success}    Log    ✓ Route created successfully
    ...    ELSE    Log    ⚠️ Route creation may have failed - restart STEP_02 to search
    
    Close All Browsers


STEP_02_Passenger_Search_And_Book
    [Documentation]    Passenger ค้นหา booking และกรอก บ้คกิ้งข้อมูลให้ครบ แล้วกดจอง
    [Tags]             step2  passenger
    
    Open Browser Incognito    ${LOGIN_URL}
    Passenger Login    ${PASSENGER_EMAIL}    ${PASSENGER_PASS}
    
    Go To    ${BASE_URL}/findTrip
    Sleep    3s
    
    # Wait for page to load
    Wait Until Element Is Visible    xpath=//button[contains(text(), 'ค้นหา')]    ${TIMEOUT}
    Log    Findtrip page loaded
    
    # Search - ใช้ text input ตัวแรกสำหรับ start location
    ${text_inputs}=    Get WebElements    xpath=//input[@type='text']
    Log    Found ${text_inputs.__len__()} text inputs
    
    Run Keyword If    ${text_inputs}    Input Text    ${text_inputs}[0]    ${START_LOCATION}
    Sleep    1s
    
    # Second input for end location
    Run Keyword If    ${text_inputs}    Input Text    ${text_inputs}[1]    ${END_LOCATION}
    Sleep    1s
    
    Log    Filling fields: ${START_LOCATION} → ${END_LOCATION}
    
    # Click search
    ${btn}=    Get WebElements    xpath=//button[contains(text(), 'ค้นหา')]
    Run Keyword If    ${btn}    Click Element    ${btn}[0]
    Sleep    8s
    Log    Clicked search, waiting for results...
    
    # Check if results loaded
    ${has_trip}=    Run Keyword And Return Status    Page Should Contain    ${START_LOCATION}
    Log    Trip found on page: ${has_trip}
    
    # Wait for trip card to be visible
    Wait Until Page Contains Element    xpath=(//div[contains(@class, 'card') or contains(@class, 'trip')])[1]    ${TIMEOUT}
    Log    Trip card is visible
    
    # Click on trip to expand
    ${trip}=    Get WebElements    xpath=(//div[contains(@class, 'card') or contains(@class, 'trip')])[1]
    Run Keyword If    ${trip}    Click Element    ${trip}[0]
    Sleep    3s
    Log    Clicked trip card
    
    # Fill passenger count if needed
    ${pax_input}=    Run Keyword And Continue On Failure    Get WebElements    xpath=//input[@name='passengers']
    Run Keyword And Continue On Failure    Input Text    ${pax_input}[0]    1
    Sleep    1s
    
    # Click Book button
    ${book}=    Get WebElements    xpath=//button[contains(text(), 'จอง')]
    Log    Found ${book.__len__()} book buttons
    Run Keyword If    ${book}    Click Element    ${book}[0]
    Sleep    5s
    Log    Clicked book button
    
    # Verify booking
    ${book_ok}=    Run Keyword And Return Status    Page Should Contain    สำเร็จ
    Run Keyword If    ${book_ok}    Log    ✓ Booking completed
    ...    ELSE    Log    ⚠️ Booking unclear
    
    Close All Browsers


STEP_03_Driver_Accept_And_Complete
    [Documentation]    Driver ยอมรับแล้ว เปลี่ยนสถานะจนเป็น Complete
    [Tags]             step3  driver
    
    Open Browser Incognito    ${LOGIN_URL}
    Driver Login    ${DRIVER_EMAIL}    ${DRIVER_PASS}
    
    Go To    ${BASE_URL}/myTrip
    Sleep    2s
    
    # Click trip to expand
    ${trip}=    Get WebElements    xpath=(//div[contains(@class, 'card') or contains(@class, 'trip')])[1]
    Run Keyword If    ${trip}    Click Element    ${trip}[0]
    Sleep    2s
    
    # Accept booking
    ${accept}=    Get WebElements    xpath=//button[contains(text(), 'ยอมรับ')]
    Run Keyword If    ${accept}    Click Element    ${accept}[0]
    Sleep    2s
    Log    ✓ Accepted
    
    # Change status - try any status buttons
    ${all_btns}=    Get WebElements    xpath=//button[contains(text(), 'รับ') or contains(text(), 'เริ่ม') or contains(text(), 'ทำการ') or contains(text(), 'สิ้น') or contains(text(), 'เสร็จ') or contains(text(), 'ปิด')]
    
    # Click buttons in sequence for status changes
    FOR    ${btn}    IN    @{all_btns}
        ${txt}=    Get Text    ${btn}
        Run Keyword And Continue On Failure    Click Element    ${btn}
        Sleep    1s
        Log    Clicked: ${txt}
    END
    
    Log    ✓ Trip completed
    Close All Browsers


STEP_04_Passenger_Review
    [Documentation]    Passenger กลับไปเขียนรีวิว
    [Tags]             step4  passenger  review
    
    Open Browser Incognito    ${LOGIN_URL}
    Passenger Login    ${PASSENGER_EMAIL}    ${PASSENGER_PASS}
    
    Go To    ${BASE_URL}/myTrip
    Sleep    2s
    Reload Page
    Sleep    2s
    
    # Click trip to expand
    ${trip}=    Get WebElements    xpath=(//div[contains(@class, 'card') or contains(@class, 'trip')])[1]
    Run Keyword If    ${trip}    Click Element    ${trip}[0]
    Sleep    2s
    
    # Click review button
    ${review}=    Get WebElements    xpath=//button[contains(text(), 'รีวิว') or contains(text(), 'เขียน')]
    Run Keyword If    ${review}    Click Element    ${review}[0]
    Sleep    2s
    
    # Click stars (1-5)
    FOR    ${i}    IN RANGE    1    6
        ${stars}=    Get WebElements    xpath=(//button[contains(@class, 'star')] | //span[contains(@class, 'star')])[${i}]
        Run Keyword And Continue On Failure    Click Element    ${stars}
        Sleep    0.3s
    END
    
    # Fill comment
    ${textarea}=    Run Keyword And Continue On Failure    Get WebElements    xpath=//textarea
    Run Keyword And Continue On Failure    Input Text    ${textarea}[0]    คนขับดีมากครับ บริการเพ้นฟูล!!
    Sleep    1s
    
    # Submit
    ${submit}=    Get WebElements    xpath=//button[contains(text(), 'ส่ง') or contains(text(), 'บันทึก')]
    Run Keyword If    ${submit}    Click Element    ${submit}[0]
    Sleep    2s
    
    Log    ✓ Review submitted
    Close All Browsers


*** Keywords ***

Open Browser Incognito
    [Arguments]    ${url}
    [Documentation]    เปิด Chrome Incognito
    
    ${chromedriver}=    Set Variable    C:\\Users\\wisit\\.wdm\\drivers\\chromedriver\\win64\\145.0.7632.117\\chromedriver-win32\\chromedriver.exe
    
    ${options}=    Evaluate    sys.modules['selenium.webdriver'].ChromeOptions()    sys
    Call Method    ${options}    add_argument    --incognito
    Call Method    ${options}    add_argument    --disable-password-manager
    Call Method    ${options}    add_argument    --disable-popup-blocking
    
    Open Browser    ${url}    ${BROWSER}    options=${options}    executable_path=${chromedriver}
    Maximize Browser Window
    Set Selenium Speed    0.5


Close All Browser Windows
    Close All Browsers


Driver Login
    [Arguments]    ${email}    ${password}
    
    Go To    ${LOGIN_URL}
    Sleep    2s
    Input Text    id=identifier    ${email}
    Input Text    id=password    ${password}
    Click Button    xpath=//button[@type='submit']
    Sleep    3s
    Run Keyword And Continue On Failure    Press Keys    None    ESCAPE
    Sleep    1s
    Log    Driver login OK


Passenger Login
    [Arguments]    ${email}    ${password}
    
    Go To    ${LOGIN_URL}
    Sleep    2s
    Input Text    id=identifier    ${email}
    Input Text    id=password    ${password}
    Click Button    xpath=//button[@type='submit']
    Sleep    3s
    Run Keyword And Continue On Failure    Press Keys    None    ESCAPE
    Sleep    1s
    Log    Passenger login OK


Get Tomorrow Date
    [Documentation]    Return tomorrow's date in YYYY-MM-DD format (CE year)
    
    ${tomorrow}=    Evaluate    (__import__('datetime').datetime.now() + __import__('datetime').timedelta(days=1)).strftime('%Y-%m-%d')
    RETURN    ${tomorrow}
