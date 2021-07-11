*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.Excel.Files
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Desktop.Windows
Library           RPA.Robocloud.Secrets

*** Keywords ***
Log In
    Open Available Browser  https://robotsparebinindustries.com/#/
    Maximize Browser Window
    ${secret}=    Get Secret    credentials
    Input Text    id:username    ${secret}[username]
    Input Password    id:password    ${secret}[password]
    Submit Form
    Wait Until Page Contains Element    id:sales-form

Open the robot order website
    Click Element When Visible     //*[@class='nav-link']

Collect CSV Download URL From User
    Add heading    https://robotsparebinindustries.com/orders.csv
    Add text input  name=geturl  label=Provide Download URL
    ${result}=      Run dialog
    [Return]    ${result.geturl}

Get orders
    ${csv_url}=    Collect CSV Download URL From User
    Download    ${csv_url}  overwrite=True
    ${csvtable}=  Read Table From Csv   orders.csv  header=True
    [Return]    ${csvtable}
    # https://robotsparebinindustries.com/orders.csv
Close the annoying modal
    Wait Until Page Contains Element    //button[text()='OK']
    Click Button    //button[text()='OK']
    Sleep    5s

Fill the form
    [Arguments]     ${row}
    Select From List By Value   id:head   ${row}[Head]
    Click Element When Visible  //input[@value='${row}[Body]']
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    id:address    ${row}[Address]
    
Preview the robot
    Click Button    id:preview

Submit the order
    Wait Until Keyword Succeeds  5x  1sec  Click Button  id:order
    Sleep    2s
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    id:receipt
    Run Keyword If    ${status}==False    Submit the order

Export The Receipt As A PDF
    [Arguments]  ${ordrnum}
    ${status}=    Run Keyword And Return Status    Page Should Contain Element    id:receipt
    Run Keyword If    ${status}==False    Submit the order
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${CURDIR}${/}output${/}${ordrnum}.pdf
    [Return]    ${CURDIR}${/}output${/}${ordrnum}.pdf

Store the receipt as a PDF file
    [Arguments]     ${receipt}
    ${path1}=    Export The Receipt As A PDF   ${receipt}
    [Return]    ${path1}

Take a screenshot of the robot
    [Arguments]  ${ScreenshotOrder}
    Capture Element Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${ScreenshotOrder}.png
    [Return]    ${CURDIR}${/}output${/}${ScreenshotOrder}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]  ${screenshot}    ${pdf}
    Open Pdf   ${pdf}
    Add Watermark Image To PDF  ${screenshot}  ${pdf}
    Close Pdf   ${pdf}

Go to order another robot
    Click Button    id:order-another
    
Create a ZIP file of the receipts
    Archive Folder With Zip     ${CURDIR}${/}output     Receipts.zip    include=*.pdf
    

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Log In
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
