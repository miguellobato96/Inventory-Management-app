const nodemailer = require('nodemailer');
require('dotenv').config();

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
    },
});

/**
 * Sends an email with exported files attached.
 * @param {string} recipient - The email recipient.
 * @param {Array} attachments - List of file paths to attach.
 */
exports.sendEmailWithAttachments = async (recipient, attachments) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: recipient,
            subject: 'Inventory Export Report',
            text: 'Attached is the requested inventory export.',
            attachments: attachments.map((file) => ({
                filename: file.split('/').pop(),
                path: file,
            })),
        };

        await transporter.sendMail(mailOptions);
        console.log(`✅ Email sent successfully to ${recipient}`);
    } catch (err) {
        console.error('❌ Error sending email:', err);
        throw err;
    }
};