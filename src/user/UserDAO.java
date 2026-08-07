package user;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import db.DBUtil;

public class UserDAO {
	// dao : �����ͺ��̽� ���� ��ü�� ���ڷμ�

	// ���������� db���� ȸ������ �ҷ����ų� db�� ȸ������ ������

	private Connection conn; // connection:db�������ϰ� ���ִ� ��ü
	private PreparedStatement pstmt;
	private ResultSet rs;

	// mysql�� ������ �ִ� �κ�

	public UserDAO() {
		try {
			conn = DBUtil.getConnection();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	// �α����� �õ��ϴ� �Լ�****

	public int login(String id, String pw) {
		String SQL = "SELECT pw FROM test.impormation WHERE id = ?";
		try {

			pstmt = conn.prepareStatement(SQL);
			pstmt.setString(1, id);
			rs = pstmt.executeQuery();

			if (rs.next()) {

				if (rs.getString(1).equals(pw)) {
					return 1; // �α��� ����
				} else
					return 0; // ��й�ȣ ����ġ
			}
			return -1; // ���̵� ���� ����
		} catch (Exception e) {
			e.printStackTrace();
		}
		return -2; // �����ͺ��̽� ������ �ǹ�
	}
	
	
	//ȸ������ �߰�
	public int sign_up(User user) {

		String SQL = "INSERT INTO test.impormation VALUES (?,?,?,?,?,?)";

		try {

			pstmt = conn.prepareStatement(SQL);

			pstmt.setString(1, user.getId());
			pstmt.setString(2, user.getPw());
			pstmt.setString(3, user.getAge());
			pstmt.setString(4, user.getName());
			pstmt.setString(5, user.getGender());
			pstmt.setString(6, user.getAddr());

			return pstmt.executeUpdate();

		} catch (Exception e) {

			e.printStackTrace();
		}
		return -1; // DB ����
	}
}