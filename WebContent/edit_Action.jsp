<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.*, java.sql.*, jakarta.servlet.http.Part"%>
<%
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);
  if (session.getAttribute("loginUser") == null) {
    response.sendRedirect("main.jsp");
    return;
  }
  request.setCharacterEncoding("UTF-8");
  String loginUser = (String) session.getAttribute("loginUser");

  String ts    = request.getParameter("ts");
  String trip  = request.getParameter("trip");
  String title = request.getParameter("title");
  String memo  = request.getParameter("memo");

  if (ts == null || ts.isEmpty() ||
      trip == null || trip.trim().isEmpty() ||
      title == null || title.trim().isEmpty() ||
      memo == null || memo.trim().isEmpty()) {
    out.println("<script>alert('빈 항목이 있습니다'); history.back();</script>");
    return;
  }

  // 이미지 처리
  String newImage = null;
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
    newImage = System.currentTimeMillis() + ext;
    imagePart.write(uploadDir + File.separator + newImage);
  }

  try {
    Connection conn = db.DBUtil.getConnection();

    // 권한 확인
    PreparedStatement chk = conn.prepareStatement(
      "SELECT id FROM test.`write` WHERE DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S')=?");
    chk.setString(1, ts);
    ResultSet chkRs = chk.executeQuery();
    if (!chkRs.next() || !loginUser.equals(chkRs.getString("id"))) {
      chkRs.close(); chk.close(); conn.close();
      out.println("<script>alert('권한이 없습니다'); history.back();</script>");
      return;
    }
    chkRs.close(); chk.close();

    PreparedStatement ps;
    if (newImage != null) {
      ps = conn.prepareStatement(
        "UPDATE test.`write` SET trip=?, title=?, memo=?, image=? WHERE DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S')=? AND id=?");
      ps.setString(1, trip);
      ps.setString(2, title);
      ps.setString(3, memo);
      ps.setString(4, newImage);
      ps.setString(5, ts);
      ps.setString(6, loginUser);
    } else {
      ps = conn.prepareStatement(
        "UPDATE test.`write` SET trip=?, title=?, memo=? WHERE DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S')=? AND id=?");
      ps.setString(1, trip);
      ps.setString(2, title);
      ps.setString(3, memo);
      ps.setString(4, ts);
      ps.setString(5, loginUser);
    }
    ps.executeUpdate();
    ps.close();
    conn.close();
    out.println("<script>location.href='List.jsp';</script>");
  } catch (Exception e) {
    e.printStackTrace();
    out.println("<script>alert('수정에 실패했습니다'); history.back();</script>");
  }
%>
