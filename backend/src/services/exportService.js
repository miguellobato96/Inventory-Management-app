const fs = require('fs');
const { Parser } = require('json2csv');
const PDFDocument = require('pdfkit');

/**
 * Groups inventory items by category and subcategory.
 * @param {Array} data - Inventory items from DB.
 * @returns {Object} - Grouped data.
 */
const groupByCategory = (data) => {
    const groupedData = {};

    data.forEach((item) => {
        const category = item.category || "Uncategorized";
        const subcategory = item.subcategory || "No Subcategory";

        if (!groupedData[category]) {
            groupedData[category] = {};
        }
        if (!groupedData[category][subcategory]) {
            groupedData[category][subcategory] = [];
        }

        groupedData[category][subcategory].push({
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            location: item.location_name,
        });
    });

    return groupedData;
};

/**
 * Generates a structured CSV file.
 */
exports.generateCSV = async (data) => {
    const filePath = `./exports/inventory_${Date.now()}.csv`;
    try {
        const groupedData = groupByCategory(data);
        let csvData = "";

        Object.entries(groupedData).forEach(([category, subcategories]) => {
            csvData += `"${category}"\n`; // Category header
            Object.entries(subcategories).forEach(([subcategory, items]) => {
                if (subcategory !== "No Subcategory") {
                    csvData += `"${subcategory}"\n`; // Subcategory header (if exists)
                }
                csvData += `"Name","Quantity","Location"\n`; // CSV Headers
                
                items.forEach((item) => {
                    csvData += `"${item.name}","${item.quantity}","${item.location}"\n`;
                });

                csvData += `\n`; // Line break after each subcategory
            });
        });

        fs.writeFileSync(filePath, csvData);
        return filePath;
    } catch (err) {
        console.error("❌ Error generating CSV:", err);
        throw err;
    }
};

/**
 * Generates a structured PDF file.
 */
exports.generatePDF = async (data) => {
    const filePath = `./exports/inventory_${Date.now()}.pdf`;
    const doc = new PDFDocument();

    try {
        doc.pipe(fs.createWriteStream(filePath));

        const groupedData = groupByCategory(data);
        doc.fontSize(20).text("Inventory Report", { align: "center" }).moveDown(2);

        Object.entries(groupedData).forEach(([category, subcategories]) => {
            doc.fontSize(18).text(`${category}`).moveDown(1); // Largest font for Category

            Object.entries(subcategories).forEach(([subcategory, items]) => {
                if (subcategory !== "No Subcategory") {
                    doc.fontSize(14).text(`${subcategory}`).moveDown(0.5); // Medium font for Subcategory
                }
                doc.fontSize(12).text("Name | Quantity | Location").moveDown(0.3);

                items.forEach((item) => {
                    doc.fontSize(10).text(`${item.name} | ${item.quantity} | ${item.location}`).moveDown(0.2); // Smallest font for items
                });

                doc.moveDown(1);
            });

            doc.moveDown(1);
        });

        doc.end();
        return filePath;
    } catch (err) {
        console.error("❌ Error generating PDF:", err);
        throw err;
    }
};