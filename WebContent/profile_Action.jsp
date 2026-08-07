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

  String loginId = (String) session.getAttribute("loginUser");
  String name   = request.getParameter("name");
  String pw     = request.getParameter("pw");
  String age    = request.getParameter("age");
  String gender = request.getParameter("gender");
  String addr   = request.getParameter("addr");

  try {
    Connection conn = db.DBUtil.getConnection();

    if (pw != null && !pw.trim().isEmpty()) {
      // 비밀번호 포함 업데이트
      PreparedStatement ps = conn.prepareStatement(
        "UPDATE test.impormation SET name=?, pw=?, age=?, gender=?, addr=? WHERE id=?");
      ps.setString(1, name);
      ps.setString(2, pw);
      ps.setString(3, age);
      ps.setString(4, gender);
      ps.setString(5, addr);
      ps.setString(6, loginId);
      ps.executeUpdate();
      ps.close();
    } else {
      // 비밀번호 제외 업데이트
      PreparedStatement ps = conn.prepareStatement(
        "UPDATE test.impormation SET name=?, age=?, gender=?, addr=? WHERE id=?");
      ps.setString(1, name);
      ps.setString(2, age);
      ps.setString(3, gender);
      ps.setString(4, addr);
      ps.setString(5, loginId);
      ps.executeUpdate();
      ps.close();
    }
    conn.close();
    response.sendRedirect("profile.jsp?msg=ok");
  } catch (Exception e) {
    e.printStackTrace();
    response.sendRedirect("profile.jsp?msg=fail");
  }
%>
