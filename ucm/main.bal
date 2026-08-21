import ballerina/io;
import ballerina/log;
import ballerina/mime;
import ballerina/zip;
import ballerinax/oraclefusion.erp.integrations;

public function main() returns error? {
    // Step 1: Compress the CSV file into a ZIP archive
    log:printInfo("Compressing CSV file to ZIP", csvFile = csvFilePath, zipFile = zipFilePath);
    check zip:compress(csvFilePath, zipFilePath);
    log:printInfo("CSV file compressed successfully");

    // Step 2: Read the ZIP file as bytes
    byte[] zipBytes = check io:fileReadBytes(zipFilePath);
    log:printInfo("ZIP file read successfully", byteCount = zipBytes.length());

    // Step 3: Encode the ZIP bytes to a Base64 string
    string|byte[]|io:ReadableByteChannel|mime:EncodeError encodedResult = mime:base64Encode(zipBytes);
    if encodedResult is mime:EncodeError {
        return error("Failed to encode ZIP file to Base64", cause = encodedResult);
    }
    if encodedResult is byte[] {
        return error("Unexpected byte[] result from base64Encode");
    }
    if encodedResult is io:ReadableByteChannel {
        return error("Unexpected ReadableByteChannel result from base64Encode");
    }
    string base64Content = encodedResult;
    log:printInfo("ZIP file encoded to Base64 successfully");

    // Step 4: Upload the Base64-encoded ZIP to Oracle Fusion UCM
    log:printInfo("Uploading file to Oracle Fusion UCM", fileName = documentFileName, account = documentAccount);
    integrations:UploadFileToUcmRequest uploadRequest = {
        documentContent: base64Content,
        documentAccount: documentAccount,
        contentType: "zip",
        fileName: documentFileName
    };
    integrations:ErpIntegrationResponse uploadResponse = check erpClient->uploadFileToUcm(uploadRequest);
    string? rawDocumentId = uploadResponse?.documentId;
    string? rawOperationName = uploadResponse?.operationName;
    string documentId = rawDocumentId ?: "N/A";
    string operationName = rawOperationName ?: "N/A";
    log:printInfo("File uploaded to Oracle Fusion UCM successfully",
        documentId = documentId,
        operationName = operationName
    );
}
