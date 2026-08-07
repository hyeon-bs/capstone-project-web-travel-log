<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*"%>
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

  String ts = request.getParameter("ts");
  if (ts == null || ts.isEmpty()) {
    response.sendRedirect("List.jsp");
    return;
  }

  try {
    Connection conn = db.DBUtil.getConnection();

    PreparedStatement ps = conn.prepareStatement(
      "DELETE FROM test.`write` WHERE DATE_FORMAT(sysdate,'%Y-%m-%d %H:%i:%S')=? AND id=?");
    ps.setString(1, ts);
    ps.setString(2, loginUser);
    int affected = ps.executeUpdate();
    ps.close();
    conn.close();

    if (affected == 0) {
      out.println("<script>alert('삭제 권한이 없거나 이미 삭제된 글입니다'); history.back();</script>");
    } else {
      out.println("<script>location.href='List.jsp';</script>");
    }
  } catch (Exception e) {
    e.printStackTrace();
    out.println("<script>alert('삭제에 실패했습니다'); history.back();</script>");
  }
%>
