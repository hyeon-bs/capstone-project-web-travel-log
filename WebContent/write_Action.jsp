<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*, java.sql.*, jakarta.servlet.http.Part"%>
<%
  if (session.getAttribute("loginUser") == null) {
    response.sendRedirect("main.jsp");
    return;
  }
  request.setCharacterEncoding("UTF-8");
  String writer = (String) session.getAttribute("loginUser"); // DB 컬럼명: id

  // 일반 폼 필드
  String trip  = request.getParameter("trip");
  String title = request.getParameter("title");
  String memo  = request.getParameter("memo");
  String wyear  = request.getParameter("wyear");
  String wmonth = request.getParameter("wmonth");
  String wday   = request.getParameter("wday");
  String wtime  = request.getParameter("wtime");
  String writeDatetime = null;
  if (wyear != null && wmonth != null && wday != null && wtime != null && !wtime.isEmpty()) {
    writeDatetime = wyear + "-" + wmonth + "-" + wday + " " + wtime + ":00";
  }

  // 입력값 검증
  if (trip == null || trip.trim().isEmpty() ||
      title == null || title.trim().isEmpty() ||
      memo == null || memo.trim().isEmpty()) {
    out.println("<script>alert('입력이 안 된 사항이 있습니다'); history.back();</script>");
    return;
  }

  // 이미지 업로드 + DB 저장
  try {
    String savedFileName = null;
    Part imagePart = request.getPart("image");
    if (imagePart != null && imagePart.getSize() > 0) {
      String uploadDir = application.getRealPath("/uploads");
      new File(uploadDir).mkdirs();

      String header = imagePart.getHeader("content-disposition");
      String originalName = "upload.jpg";
      for (String token : header.split(";")) {
        if (token.trim().startsWith("filename")) {
          originalName = token.substring(token.indexOf('=') + 1).trim().replace("\"", "");
        }
      }
      String ext = originalName.contains(".") ? originalName.substring(originalName.lastIndexOf('.')) : ".jpg";
      savedFileName = System.currentTimeMillis() + ext;
      imagePart.write(uploadDir + File.separator + savedFileName);
    }

    Connection conn = db.DBUtil.getConnection();
    String dateVal = (writeDatetime != null) ? "?" : "NOW()";
    PreparedStatement pstmt = conn.prepareStatement(
      "INSERT INTO test.`write` (trip, title, memo, image, sysdate, id) VALUES (?,?,?,?," + dateVal + ",?)");
    pstmt.setString(1, trip);
    pstmt.setString(2, title);
    pstmt.setString(3, memo);
    pstmt.setString(4, savedFileName);
    if (writeDatetime != null) {
      pstmt.setString(5, writeDatetime);
      pstmt.setString(6, writer);
    } else {
      pstmt.setString(5, writer);
    }
    pstmt.executeUpdate();
    pstmt.close();
    conn.close();
    out.println("<script>location.href='Calendar.jsp';</script>");
  } catch (Exception e) {
    e.printStackTrace();
    out.println("<script>alert('오류: " + e.getMessage() + "'); history.back();</script>");
  }
%>
