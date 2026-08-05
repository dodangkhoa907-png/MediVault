# syntax=docker/dockerfile:1

# ══════════════════════════════════════════════════════════════════════════
# STAGE 1 — BUILD: biên dịch WAR bằng Maven (không đóng gói vào image cuối)
# ══════════════════════════════════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml trước rồi tải dependency riêng — tận dụng layer cache của Docker:
# nếu chỉ sửa code (không đổi pom.xml) thì bước tải dependency KHÔNG chạy lại,
# build lại nhanh hơn nhiều lần so với copy hết rồi mới mvn.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ══════════════════════════════════════════════════════════════════════════
# STAGE 2 — RUNTIME: Tomcat 10.1 (bắt buộc — app dùng Jakarta Servlet 6.0,
# Tomcat 10.0.x KHÔNG tương thích) chạy trên JDK 17 (bắt buộc theo pom.xml).
# ══════════════════════════════════════════════════════════════════════════
FROM tomcat:10.1-jdk17-temurin
ENV TZ=Asia/Ho_Chi_Minh

# Xoá app mẫu có sẵn của Tomcat (docs/examples/manager/host-manager) — giảm
# surface tấn công + giảm dung lượng image, không phần nào trong đó cần cho production.
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy dưới dạng ROOT.war để app chạy ở "/" thay vì "/MediCare" — mọi link
# trong code đều dùng request.getContextPath() động nên tự thích ứng, không cần sửa gì.
COPY --from=build /app/target/MediCare.war /usr/local/tomcat/webapps/ROOT.war

# Render (và nhiều PaaS khác) gán cổng lắng nghe qua biến môi trường PORT lúc chạy,
# không cố định trước — entrypoint riêng sẽ vá vào server.xml đúng lúc container khởi động.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 8080

# ── Tối ưu khởi động & runtime cho container ──
# - UseContainerSupport + MaxRAMPercentage: JVM tự dò giới hạn RAM thật của container
#   (cgroup) thay vì -Xmx cố định — đổi gói Render (RAM khác) không cần sửa lại Dockerfile,
#   cũng tránh bị OOM-kill khi gói nhỏ hơn số cố định trước đó.
# - java.security.egd=file:/dev/./urandom: bỏ chặn khởi động chờ entropy thật (ảnh hưởng
#   SecureRandom dùng để sinh session ID) — cải thiện rõ rệt thời gian Tomcat start trong container.
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom -Duser.timezone=Asia/Ho_Chi_Minh"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["catalina.sh", "run"]
