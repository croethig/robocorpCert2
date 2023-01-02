*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${webstoreURL}=    Get webstore URL from vault
    ${csvURL}=    Asking user for CSV URL
    Open the robot order website    ${webstoreURL}
    ${orders}=    Get orders    ${csvURL}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal

        Fill the form using the CSV data    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Get webstore URL from vault
    ${secret}=    Get Secret    topSecret
    #${webstoreURL}=    "https://robotsparebinindustries.com/#/robot-order"
    RETURN    ${secret}[url]

Open the robot order website
    [Arguments]    ${webstoreURL}
    #Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Open Available Browser    ${webstoreURL}

Close the annoying modal
    #Wait And Click Button    //button[@class="btn btn-dark"]
    Click Button When Visible    //button[@class="btn btn-dark"]

Asking user for CSV URL
    Add heading    Please provide the URL of the CSV file (ex. https://robotsparebinindustries.com/orders.csv)
    Add text input    url
    ${result}=    Run dialog
    RETURN    ${result.url}

Get orders
    [Arguments]    ${urlCSV}
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${urlCSV}    overwrite=True
    ${orders}=    RPA.Tables.Read table from CSV    orders.csv    header=True
    RETURN    ${orders}

Fill the form using the CSV data
    [Arguments]    ${row}
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    //input[@class="form-control"]    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Wait Until Keyword Succeeds    1min    500ms    Try to submit order

Try to submit order
    Click Button    order
    Page Should Contain Element    id:receipt
    #this tests if there was an error: no receipt, returns fail

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${filename}
    Wait Until Element Is Visible    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${filename}.pdf

Take a screenshot of the robot
    [Arguments]    ${filename}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}${filename}.PNG

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${filename}
    Open Pdf    ${OUTPUT_DIR}${/}${filename}.pdf
    ${Files}=    Create List
    ...    ${OUTPUT_DIR}${/}${filename}.PNG
    ...    ${OUTPUT_DIR}${/}${filename}.pdf
    Add Files To Pdf    ${Files}    ${OUTPUT_DIR}${/}${filename}.pdf

    Close Pdf    ${OUTPUT_DIR}${/}${filename}.pdf

Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}Invoices.zip
