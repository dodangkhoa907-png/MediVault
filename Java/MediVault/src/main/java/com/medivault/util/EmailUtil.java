package com.medivault.util;

import jakarta.mail.*;
import jakarta.mail.internet.*;
import java.util.Properties;

public class EmailUtil {
    private static final String HOST     = "smtp.gmail.com";
    private static final String PORT     = "587";
    private static final String USERNAME = "dodangkhoa907@gmail.com";
    private static final String PASSWORD = "qhbh kqkg xwxd ugwm";

    /**
     * Gửi email (hỗ trợ HTML).
     * Không throws ra ngoài — lỗi được log và trả về false.
     * @return true nếu gửi thành công, false nếu thất bại
     */
    public static boolean sendEmail(String toAddress, String subject, String body) {
        try {
            Properties props = new Properties();
            props.put("mail.smtp.host", HOST);
            props.put("mail.smtp.port", PORT);
            props.put("mail.smtp.auth", "true");
            props.put("mail.smtp.starttls.enable", "true");

            Session session = Session.getInstance(props, new Authenticator() {
                @Override
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(USERNAME, PASSWORD);
                }
            });

            Message message = new MimeMessage(session);
            message.setFrom(new InternetAddress(USERNAME));
            message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(toAddress));
            message.setSubject(subject);
            message.setContent(body, "text/html;charset=UTF-8");
            Transport.send(message);
            return true;
        } catch (MessagingException e) {
            System.err.println("[EmailUtil] Gửi email thất bại → " + toAddress + " | " + e.getMessage());
            return false;
        }
    }
}