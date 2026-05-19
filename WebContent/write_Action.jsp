<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="user.WriteDAO"%>

<!-- bbsdao의 클래스 가져옴 -->
<%@ page import="java.io.PrintWriter"%>

<!-- 자바 클래스 사용 -->
<%
	request.setCharacterEncoding("UTF-8");
	response.setContentType("text/html; charset=UTF-8"); //set으로쓰는습관들이세오.
%>

<!-- 한명의 회원정보를 담는 user클래스를 자바 빈즈로 사용 / scope:페이지 현재의 페이지에서만 사용-->

<jsp:useBean id="user" class="user.User" scope="page" />

<jsp:setProperty name="user" property="trip" />
<jsp:setProperty name="user" property="title" />
<jsp:setProperty name="user" property="memo" />

<%
	System.out.println(user);
%>

<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

<title>글쓰기</title>
</head>
<body>
	<%
		if (user.getTrip() == null || user.getTitle() == null || user.getMemo() == null) {
			PrintWriter script = response.getWriter();
			script.println("<script>");
			script.println("alert('입력이 안된 사항이 있습니다')");
			script.println("history.back()");
			script.println("</script>");

		} else {

			WriteDAO WriteDAO = new WriteDAO();
			int result = WriteDAO.write(user);
			if (result == -1) {

				PrintWriter script = response.getWriter();
				script.println("<script>");
				script.println("alert('글쓰기에 실패했습니다')");
				script.println("history.back()");
				script.println("</script>");

			} else {

				PrintWriter script = response.getWriter();
				script.println("<script>");
				script.println("location.href='Calendar.jsp'");
				script.println("</script>");
			}
		}
	%>

</body>

</html>