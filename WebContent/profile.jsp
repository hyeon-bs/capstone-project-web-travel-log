<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="java.sql.*"%>
<%
  response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  response.setHeader("Pragma", "no-cache");
  response.setDateHeader("Expires", 0);
  if (session.getAttribute("loginUser") == null) {
    response.sendRedirect("main.jsp");
    return;
  }
  String loginId = (String) session.getAttribute("loginUser");

  String dbName = "", dbAge = "", dbGender = "", dbAddr = "";
  try {
    Connection conn = db.DBUtil.getConnection();
    PreparedStatement ps = conn.prepareStatement(
      "SELECT name, age, gender, addr FROM test.impormation WHERE id=?");
    ps.setString(1, loginId);
    ResultSet rs = ps.executeQuery();
    if (rs.next()) {
      dbName   = rs.getString("name")   != null ? rs.getString("name")   : "";
      dbAge    = rs.getString("age")    != null ? rs.getString("age")    : "";
      dbGender = rs.getString("gender") != null ? rs.getString("gender") : "";
      dbAddr   = rs.getString("addr")   != null ? rs.getString("addr")   : "";
    }
    rs.close(); ps.close(); conn.close();
  } catch (Exception e) { e.printStackTrace(); }

  String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TravelLog — 내 정보</title>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; background: #0f172a; min-height: 100vh; color: #fff; }

  .nav-bar {
    display: flex; align-items: center; justify-content: space-between;
    padding: 14px 28px; background: rgba(10,15,35,0.9);
    border-bottom: 1px solid rgba(255,255,255,0.08);
    position: sticky; top: 0; z-index: 10; backdrop-filter: blur(12px);
  }
  .nav-logo { font-size: 20px; font-weight: 700; }
  .nav-logo span { color: #60a5fa; }
  .nav-actions { display: flex; gap: 10px; }
  .nav-btn {
    padding: 7px 14px; border-radius: 8px; border: none;
    font-size: 13px; font-weight: 500; cursor: pointer;
    font-family: 'Inter', sans-serif; transition: all 0.15s;
  }
  .nav-btn-ghost { background: rgba(255,255,255,0.08); color: rgba(255,255,255,0.8); border: 1px solid rgba(255,255,255,0.12); }
  .nav-btn-ghost:hover { background: rgba(255,255,255,0.14); color: #fff; }

  .page-wrapper { max-width: 520px; margin: 60px auto; padding: 0 20px 80px; }

  .profile-card {
    background: rgba(255,255,255,0.05);
    border: 1px solid rgba(255,255,255,0.1);
    border-radius: 20px;
    padding: 40px 36px;
    box-shadow: 0 20px 50px rgba(0,0,0,0.4);
  }

  .profile-avatar {
    width: 80px; height: 80px; border-radius: 50%;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    display: flex; align-items: center; justify-content: center;
    font-size: 36px; margin: 0 auto 20px;
  }

  .profile-id {
    text-align: center; font-size: 13px; color: rgba(255,255,255,0.4);
    margin-bottom: 32px;
  }
  .profile-id strong { color: #60a5fa; font-size: 15px; }

  .form-group { margin-bottom: 16px; }
  .form-group label {
    display: block; font-size: 11px; font-weight: 600;
    color: rgba(255,255,255,0.45); text-transform: uppercase;
    letter-spacing: 0.8px; margin-bottom: 7px;
  }
  .form-group input,
  .form-group select {
    width: 100%; padding: 12px 14px;
    background: rgba(255,255,255,0.07);
    border: 1px solid rgba(255,255,255,0.12);
    border-radius: 10px;
    color: #fff; font-size: 14px; font-family: 'Inter', sans-serif;
    outline: none; transition: border-color 0.2s, background 0.2s;
    appearance: none;
  }
  .form-group input::placeholder { color: rgba(255,255,255,0.3); }
  .form-group input:focus,
  .form-group select:focus { border-color: #60a5fa; background: rgba(96,165,250,0.08); }
  .form-group select option { background: #162032; color: #fff; }

  .pw-hint { font-size: 11px; color: rgba(255,255,255,0.3); margin-top: 5px; }

  .btn-save {
    width: 100%; padding: 13px;
    background: linear-gradient(135deg, #3b82f6, #1d4ed8);
    border: none; border-radius: 12px;
    color: #fff; font-size: 15px; font-weight: 600;
    cursor: pointer; margin-top: 8px;
    transition: transform 0.15s, box-shadow 0.15s;
    font-family: 'Inter', sans-serif;
  }
  .btn-save:hover { transform: translateY(-1px); box-shadow: 0 10px 28px rgba(59,130,246,0.5); }

  .toast {
    display: none; margin-bottom: 20px;
    padding: 12px 16px; border-radius: 10px;
    font-size: 13px; font-weight: 500; text-align: center;
  }
  .toast.success { background: rgba(52,211,153,0.15); border: 1px solid rgba(52,211,153,0.3); color: #34d399; display: block; }
  .toast.error   { background: rgba(239,68,68,0.15);  border: 1px solid rgba(239,68,68,0.3);  color: #f87171; display: block; }
</style>
</head>
<body>

<nav class="nav-bar">
  <div class="nav-logo">Travel<span>Log</span></div>
  <div class="nav-actions">
    <button class="nav-btn nav-btn-ghost" onclick="history.back()">← 뒤로</button>
  </div>
</nav>

<div class="page-wrapper">
  <div class="profile-card">
    <div class="profile-avatar">👤</div>
    <div class="profile-id">아이디: <strong><%=loginId%></strong></div>

    <% if ("ok".equals(msg)) { %>
    <div class="toast success">✓ 정보가 성공적으로 업데이트되었습니다.</div>
    <% } else if ("fail".equals(msg)) { %>
    <div class="toast error">✗ 업데이트에 실패했습니다. 다시 시도해주세요.</div>
    <% } %>

    <form method="post" action="profile_Action.jsp">
      <div class="form-group">
        <label>이름</label>
        <input type="text" name="name" value="<%=dbName%>" placeholder="이름 입력">
      </div>
      <div class="form-group">
        <label>새 비밀번호</label>
        <input type="password" name="pw" placeholder="변경할 비밀번호 입력">
        <div class="pw-hint">비워두면 기존 비밀번호가 유지됩니다.</div>
      </div>
      <div class="form-group">
        <label>나이</label>
        <input type="text" name="age" value="<%=dbAge%>" placeholder="나이 입력" maxlength="3">
      </div>
      <div class="form-group">
        <label>성별</label>
        <select name="gender">
          <option value="" <%="".equals(dbGender)?"selected":""%>>선택 안함</option>
          <option value="남" <%="남".equals(dbGender)?"selected":""%>>남</option>
          <option value="여" <%="여".equals(dbGender)?"selected":""%>>여</option>
        </select>
      </div>
      <div class="form-group">
        <label>주소</label>
        <input type="text" name="addr" value="<%=dbAddr%>" placeholder="주소 입력">
      </div>
      <button type="submit" class="btn-save">저장하기</button>
    </form>
  </div>
</div>

</body>
</html>
