*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.
...

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Email.ImapSmtp
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Close the pop-up
    ${orders}=    Get orders
    Create ZIP file


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${orderlist}=    Read table from CSV    orders.csv
    FOR    ${orderline}    IN    @{orderlist}
        Fill the form    ${orderline}
        Click Button    preview
        Wait Until Keyword Succeeds    5x    1s    Submit order
        ${pdf}=    Store the receipt as a PDF file    ${orderline}[Order number]
        ${screenshot}=    Take a screenshot of the robot image    ${orderline}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Order another robot
        Close the pop-up
    END
    RETURN    ${orderlist}

Close the pop-up
    Click Button    OK

Fill the Form
    [Arguments]    ${orderdata}
    Select From List By Value    head    ${orderdata}[Head]
    Select Radio Button    body    ${orderdata}[Body]
    Input Text    xpath://input[@class="form-control"]    ${orderdata}[Legs]
    Input Text    address    ${orderdata}[Address]

Submit order
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${ordernr}
    ${pdf_location}=    Set Variable    ${OUTPUT_DIR}${/}receipts/PDF/receipt${ordernr}.pdf
    ${result}=    Get Element Attribute    id:receipt    outerHTML
    ${result}=    Html To Pdf    ${result}    ${pdf_location}
    RETURN    ${pdf_location}

Take a screenshot of the robot image
    [Arguments]    ${ordernr}
    ${screenshot_location}=    Set Variable    ${OUTPUT_DIR}${/}receipts/PNG/robot${ordernr}.png
    ${screenshot}=    Screenshot    robot-preview-image    ${screenshot_location}
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    ${files}=    Create List    ${pdf}    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    # Close Pdf    ${pdf}

Order another robot
    Click Button    order-another

Create ZIP file
    ${receipt_folder}=    Set Variable    ${OUTPUT_DIR}${/}receipts/PDF
    ${ZIP_location}=    Set Variable    ${OUTPUT_DIR}${/}ReceiptsZIP.zip
    Archive Folder With Zip    ${receipt_folder}    ${ZIP_location}
