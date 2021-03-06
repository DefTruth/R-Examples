# This file was generated by Rcpp::compileAttributes
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

RcppConvertFromExcelRef2 <- function(r) {
    .Call('openxlsx_RcppConvertFromExcelRef2', PACKAGE = 'openxlsx', r)
}

RcppConvertFromExcelRef <- function(x) {
    .Call('openxlsx_RcppConvertFromExcelRef', PACKAGE = 'openxlsx', x)
}

calcColumnWidths <- function(sheetData, sharedStrings, autoColumns, widths, baseFontCharWidth, minW, maxW) {
    .Call('openxlsx_calcColumnWidths', PACKAGE = 'openxlsx', sheetData, sharedStrings, autoColumns, widths, baseFontCharWidth, minW, maxW)
}

cppReadFile <- function(xmlFile) {
    .Call('openxlsx_cppReadFile', PACKAGE = 'openxlsx', xmlFile)
}

cppReadFile2 <- function(xmlFile) {
    .Call('openxlsx_cppReadFile2', PACKAGE = 'openxlsx', xmlFile)
}

getVals <- function(x) {
    .Call('openxlsx_getVals', PACKAGE = 'openxlsx', x)
}

getNodes <- function(xml, tagIn) {
    .Call('openxlsx_getNodes', PACKAGE = 'openxlsx', xml, tagIn)
}

getChildlessNode_ss <- function(xml, tag) {
    .Call('openxlsx_getChildlessNode_ss', PACKAGE = 'openxlsx', xml, tag)
}

getChildlessNode <- function(xml, tag) {
    .Call('openxlsx_getChildlessNode', PACKAGE = 'openxlsx', xml, tag)
}

getAttr <- function(x, tag) {
    .Call('openxlsx_getAttr', PACKAGE = 'openxlsx', x, tag)
}

getCellStyles <- function(x) {
    .Call('openxlsx_getCellStyles', PACKAGE = 'openxlsx', x)
}

getCellTypes <- function(x) {
    .Call('openxlsx_getCellTypes', PACKAGE = 'openxlsx', x)
}

getCells <- function(x) {
    .Call('openxlsx_getCells', PACKAGE = 'openxlsx', x)
}

getFunction <- function(x) {
    .Call('openxlsx_getFunction', PACKAGE = 'openxlsx', x)
}

getRefs <- function(x, startRow) {
    .Call('openxlsx_getRefs', PACKAGE = 'openxlsx', x, startRow)
}

getSharedStrings <- function(xmlFile, isFile) {
    .Call('openxlsx_getSharedStrings', PACKAGE = 'openxlsx', xmlFile, isFile)
}

getNumValues <- function(inFile, n, tagIn) {
    .Call('openxlsx_getNumValues', PACKAGE = 'openxlsx', inFile, n, tagIn)
}

writeFile <- function(parent, xmlText, parentEnd, R_fileName) {
    .Call('openxlsx_writeFile', PACKAGE = 'openxlsx', parent, xmlText, parentEnd, R_fileName)
}

buildCellList <- function(r, t, v) {
    .Call('openxlsx_buildCellList', PACKAGE = 'openxlsx', r, t, v)
}

buildLoadCellList <- function(r, t, v, f) {
    .Call('openxlsx_buildLoadCellList', PACKAGE = 'openxlsx', r, t, v, f)
}

constructCellData <- function(cols, LETTERS, rows, t, v) {
    .Call('openxlsx_constructCellData', PACKAGE = 'openxlsx', cols, LETTERS, rows, t, v)
}

convert2ExcelRef <- function(cols, LETTERS) {
    .Call('openxlsx_convert2ExcelRef', PACKAGE = 'openxlsx', cols, LETTERS)
}

buildMatrixNumeric <- function(v, rowInd, colInd, colNames, nRows, nCols) {
    .Call('openxlsx_buildMatrixNumeric', PACKAGE = 'openxlsx', v, rowInd, colInd, colNames, nRows, nCols)
}

buildMatrixMixed <- function(v, rowInd, colInd, colNames, nRows, nCols, charCols, dateCols, originAdj) {
    .Call('openxlsx_buildMatrixMixed', PACKAGE = 'openxlsx', v, rowInd, colInd, colNames, nRows, nCols, charCols, dateCols, originAdj)
}

matrixRowInds <- function(indices) {
    .Call('openxlsx_matrixRowInds', PACKAGE = 'openxlsx', indices)
}

matrixRowInds2 <- function(x) {
    .Call('openxlsx_matrixRowInds2', PACKAGE = 'openxlsx', x)
}

buildCellMerges <- function(comps) {
    .Call('openxlsx_buildCellMerges', PACKAGE = 'openxlsx', comps)
}

quickBuildCellXML <- function(prior, post, sheetData, rowNumbers, styleInds, R_fileName) {
    .Call('openxlsx_quickBuildCellXML', PACKAGE = 'openxlsx', prior, post, sheetData, rowNumbers, styleInds, R_fileName)
}

buildTableXML <- function(table, ref, colNames, showColNames, tableStyle, withFilter) {
    .Call('openxlsx_buildTableXML', PACKAGE = 'openxlsx', table, ref, colNames, showColNames, tableStyle, withFilter)
}

uniqueCellAppend <- function(sheetData, r, newCells) {
    .Call('openxlsx_uniqueCellAppend', PACKAGE = 'openxlsx', sheetData, r, newCells)
}

getHyperlinkRefs <- function(x) {
    .Call('openxlsx_getHyperlinkRefs', PACKAGE = 'openxlsx', x)
}

writeCellStyles <- function(sheetData, rows, cols, styleId, LETTERS) {
    .Call('openxlsx_writeCellStyles', PACKAGE = 'openxlsx', sheetData, rows, cols, styleId, LETTERS)
}

calcNRows <- function(x, skipEmptyRows) {
    .Call('openxlsx_calcNRows', PACKAGE = 'openxlsx', x, skipEmptyRows)
}

buildCellTypes <- function(classes, nRows) {
    .Call('openxlsx_buildCellTypes', PACKAGE = 'openxlsx', classes, nRows)
}

removeEmptyNodes <- function(x, emptyNodes) {
    .Call('openxlsx_removeEmptyNodes', PACKAGE = 'openxlsx', x, emptyNodes)
}

getCellsWithChildrenLimited <- function(xmlFile, emptyNodes, n) {
    .Call('openxlsx_getCellsWithChildrenLimited', PACKAGE = 'openxlsx', xmlFile, emptyNodes, n)
}

getCellsWithChildren <- function(xmlFile, emptyNodes) {
    .Call('openxlsx_getCellsWithChildren', PACKAGE = 'openxlsx', xmlFile, emptyNodes)
}

quickBuildCellXML2 <- function(prior, post, sheetData, rowNumbers, styleInds, rowHeights, R_fileName) {
    .Call('openxlsx_quickBuildCellXML2', PACKAGE = 'openxlsx', prior, post, sheetData, rowNumbers, styleInds, rowHeights, R_fileName)
}

getRefsVals <- function(x, startRow) {
    .Call('openxlsx_getRefsVals', PACKAGE = 'openxlsx', x, startRow)
}

createAlignmentNode <- function(style) {
    .Call('openxlsx_createAlignmentNode', PACKAGE = 'openxlsx', style)
}

createFillNode <- function(style) {
    .Call('openxlsx_createFillNode', PACKAGE = 'openxlsx', style)
}

createFontNode <- function(style, defaultFontSize, defaultFontColour, defaultFontName) {
    .Call('openxlsx_createFontNode', PACKAGE = 'openxlsx', style, defaultFontSize, defaultFontColour, defaultFontName)
}

createBorderNode <- function(style, borders) {
    .Call('openxlsx_createBorderNode', PACKAGE = 'openxlsx', style, borders)
}

getCellStylesPossiblyMissing <- function(x) {
    .Call('openxlsx_getCellStylesPossiblyMissing', PACKAGE = 'openxlsx', x)
}

readWorkbook <- function(v, r, string_refs, is_date, nRows, hasColNames, skipEmptyRows, originAdj, clean_names) {
    .Call('openxlsx_readWorkbook', PACKAGE = 'openxlsx', v, r, string_refs, is_date, nRows, hasColNames, skipEmptyRows, originAdj, clean_names)
}

getCellInfo <- function(xmlFile, sharedStrings, skipEmptyRows, startRow, rows, getDates) {
    .Call('openxlsx_getCellInfo', PACKAGE = 'openxlsx', xmlFile, sharedStrings, skipEmptyRows, startRow, rows, getDates)
}

loadworksheets <- function(wb, styleObjects, xmlFiles, is_chart_sheet) {
    .Call('openxlsx_loadworksheets', PACKAGE = 'openxlsx', wb, styleObjects, xmlFiles, is_chart_sheet)
}

ExcelConvertExpand <- function(cols, LETTERS, rows) {
    .Call('openxlsx_ExcelConvertExpand', PACKAGE = 'openxlsx', cols, LETTERS, rows)
}

buildMatrixNumeric2 <- function(v, rowInd, colInd, nRows, nCols) {
    .Call('openxlsx_buildMatrixNumeric2', PACKAGE = 'openxlsx', v, rowInd, colInd, nRows, nCols)
}

readWorkbook2 <- function(v, r, string_refs, is_date, nRows, hasColNames, skipEmptyRows, originAdj, clean_names) {
    .Call('openxlsx_readWorkbook2', PACKAGE = 'openxlsx', v, r, string_refs, is_date, nRows, hasColNames, skipEmptyRows, originAdj, clean_names)
}

