function Add-WordTableTitle {
    [CmdletBinding()]
    param(
        $Table,
        $Titles,
        $MaximumColumns
    )
    #Write-Debug "Title Count $($Titles.Count) "
    #Write-Color "Title Count $($Titles.Count) " -Color Yellow
    for ($a = 0; $a -lt $Titles.Count; $a++) {
        if ($Titles[$a] -is [string]) {
            #$Titles[$a].GetType()
            $ColumnName = $Titles[$a]
        } else {
            $ColumnName = $Titles[$a].Name
        }
        #Write-Color "Column Name: $ColumnName" -Color DarkBlue
        Add-WordTableCellValue -Table $Table -Row 0 -Column $a -Value $ColumnName -Supress $Supress
        if ($a -eq $($MaximumColumns - 1)) {
            break;
        }
    }
}
function Add-WordTableCellValue {
    [CmdletBinding()]
    param(
        $Table,
        $Row,
        $Column,
        $Value,
        $Paragraph = 0,
        [bool] $Supress = $true
    )
    Write-Verbose "Add-WordTableCellValue - Row: $Row Column $Column Value $Value"
    $Data = $Table.Rows[$Row].Cells[$Column].Paragraphs[$Paragraph].Append($Value)
    if ($Supress -eq $true) { return } else { return $Data }
}
function Add-WordTable {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)] [Xceed.Words.NET.Container] $WordDocument,
        [parameter(ValueFromPipelineByPropertyName, ValueFromPipeline)][Xceed.Words.NET.InsertBeforeOrAfter] $Paragraph,
        [ValidateNotNullOrEmpty()]$Table,
        [TableDesign] $Design = [TableDesign]::ColorfulList,
        [int] $MaximumColumns = 5,
        [string[]]$Columns = ('Name', 'Value'),
        [bool] $Supress = $true
    )

    ### Verbose Information START
    #$Table.GetType()
    #$Table | Get-Member | ft -a
    ### Verbose Information END
    Write-Verbose "Add-WordTable - Table row count: $(Get-ObjectCount $table)"
    Write-Verbose "Add-WordTable - GetType Before Conversion:  $($Table.GetType().Name)"
    $Table = $Table | Select-Object *
    Write-Verbose "Add-WordTable - GetType After Conversion:  $($Table.GetType().Name)"

    if ($Table.GetType().Name -eq 'PSCustomObject') {
        Write-Verbose 'Add-WordTable - Option 1'
        $Titles = Get-ObjectTitles -Object $Table
        #$Titles
        $NumberRows = $Titles.Count + 1
        $NumberColumns = 2

        if ($Paragraph -eq $null) {
            $WordTable = $WordDocument.InsertTable($NumberRows, $NumberColumns)
        } else {
            $TableDefinition = $WordDocument.AddTable($NumberRows, $NumberColumns)
            $WordTable = $Paragraph.InsertTableAfterSelf($TableDefinition)
        }

        $WordTable.Design = $Design

        ### Uses $Columns from $top

        $Titles = Add-WordTableTitle -Title $Columns -Table $WordTable -MaximumColumns $MaximumColumns
        $Row = 1
        foreach ($Title in $Titles) {
            $Value = Get-ObjectData -Object $Table -Title $Title -DoNotAddTitles

            $ColumnTitle = 0
            $ColumnData = 1
            $Data = Add-WordTableCellValue -Table $WordTable -Row $Row -Column $ColumnTitle -Value $Title
            $Data = Add-WordTableCellValue -Table $WordTable -Row $Row -Column $ColumnData -Value $Value
            Write-Verbose "Add-WordTable - Title:  $Title Value: $Value Row: $Row -Color"
            $Row++

        }
    } elseif ($Table.GetType().Name -eq 'Object[]') {
        write-verbose 'Add-WordTable - option 3'

        $Titles = Get-ObjectTitles -Object $Table

        $NumberColumns = if ($Titles.Count -ge $MaximumColumns) { $MaximumColumns } else { $Titles.Count }
        $NumberRows = $Table.Count

        Write-Verbose "Add-WordTable - Column Count $($NumberColumns) Rows Count $NumberRows "
        #Write-Color "Column Count ", $NumberColumns, " Rows Count ", $NumberRows -C Yellow, Green, Yellow, Green

        if ($Paragraph -eq $null) {
            $WordTable = $WordDocument.InsertTable($NumberRows, $NumberColumns)
        } else {
            $TableDefinition = $WordDocument.AddTable($NumberRows, $NumberColumns)
            $WordTable = $Paragraph.InsertTableAfterSelf($TableDefinition)
        }
        $WordTable.Design = $Design

        Add-WordTableTitle -Title $Titles -Table $WordTable -MaximumColumns $MaximumColumns

        for ($b = 1; $b -lt $NumberRows; $b++) {
            $a = 0
            foreach ($Title in $Titles) {
                $Data = Add-WordTableCellValue -Table $WordTable -Row $b -Column $a -Value $Table[$b].$Title
                if ($a -eq $($MaximumColumns - 1)) { break; } # prevents display of more columns then there is space, choose carefully
                $a++
            }
        }
    } else {
        Write-Verbose 'Add-WordTable - Option 2'
        $pattern = 'string|bool|byte|char|decimal|double|float|int|long|sbyte|short|uint|ulong|ushort'
        $Columns = ($Table | Get-Member | Where-Object { $_.MemberType -like "*Property" -and $_.Definition -match $pattern }) | Select-Object Name
        #$Columns
        $NumberColumns = if ($Columns.Count -ge $MaximumColumns) { $MaximumColumns } else { $Columns.Count }
        $NumberRows = $Table.Count

        Write-Verbose "Add-WordTable - Column Count $($NumberColumns) Rows Count $NumberRows "
        #Write-Color "Column Count ", $NumberColumns, " Rows Count ", $NumberRows -C Yellow, Green, Yellow, Green

        if ($Paragraph -eq $null) {
            $WordTable = $WordDocument.InsertTable($NumberRows, $NumberColumns)
        } else {
            $TableDefinition = $WordDocument.AddTable($NumberRows, $NumberColumns)
            $WordTable = $Paragraph.InsertTableAfterSelf($TableDefinition)
        }
        $WordTable.Design = $Design

        $Titles = Add-WordTableTitle -Title $Columns -Table $WordTable -MaximumColumns $MaximumColumns

        for ($b = 1; $b -lt $NumberRows; $b++) {
            $a = 0
            foreach ($Title in $Columns.Name) {
                $Data = Add-WordTableCellValue -Table $WordTable -Row $b -Column $a -Value $Table[$b].$Title
                if ($a -eq $($MaximumColumns - 1)) { break; } # prevents display of more columns then there is space, choose carefully
                $a++


            }
        }

    }
    if ($Supress -eq $false) { return $WordTable } else { return }
}