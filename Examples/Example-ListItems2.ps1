Import-Module PSWriteWord -Force

$FilePath = "$Env:USERPROFILE\Desktop\PSWriteWord-Example-ListItems2.docx"
$ListOfItems = @('Test1', 'Test2', 'Test3', 'Test4', 'Test5')

$WordDocument = New-WordDocument $FilePath

$p = $WordDocument.InsertParagraph("This is text after which will be bulleted list").FontSize(15)
$list = Add-WordList -WordDocument $WordDocument -ListType Bulleted -ListData $ListOfItems -Supress $false -Verbose
#$list.GetType()
#$List.AddItem

$Data = $WordDocument.AddListItem($list, 'test 20')
#$List.AddItemWithStartValue(
#$list.AddItem($p1)

#$p.AddItem('test')

Add-WordSection -WordDocument $WordDocument -PageBreak

$p = $WordDocument.InsertParagraph("This is another text, after which will be numbered list").FontSize(15)
Add-WordList -WordDocument $WordDocument -ListType Numbered -ListData $ListOfItems

Save-WordDocument $WordDocument