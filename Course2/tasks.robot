*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders
    Create ZIP file of receipt PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Click Button    Yep

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orderfile}=    Read table from CSV    orders.csv
    FOR    ${orderline}    IN    @{orderfile}
        Fill the form for one order    ${orderline}
        ${pdf}=    Store the receipt as a PDF file    ${orderline}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${orderline}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order more robots
        Close the annoying modal
    END
    RETURN    ${orderfile}

Fill the form for one order
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://input[@class="form-control"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    5x    1s    Submit order

Submit order
    Click Button    Order
    ${result}=    Page Should Contain Element    order-another
    WHILE    ${result} != None
        Click Button    Order
    END

Store the receipt as a PDF file
    [Arguments]    ${ordernr}
    Wait Until Element Is Visible    order-another
    ${robot_receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    ${pdf_location}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}PDF${/}robot-receipt${ordernr}.pdf
    Html To Pdf    ${robot_receipt_html}    ${pdf_location}
    RETURN    ${pdf_location}

Take a screenshot of the robot
    [Arguments]    ${ordernr}
    ${screenshot_location}=    Set Variable    ${OUTPUT_DIR}${/}receipts${/}PNG${/}robot${ordernr}.png
    Screenshot    id:robot-preview-image    ${screenshot_location}
    RETURN    ${screenshot_location}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open PDF    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To PDF    ${files}    ${pdf}
    Close Pdf    ${pdf}

Order more robots
    Click Button    order-another

Create ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDF-receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts${/}PDF    ${zip_file_name}
