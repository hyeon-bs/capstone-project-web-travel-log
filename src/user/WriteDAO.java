package user;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import db.DBUtil;

public class WriteDAO {
	// dao : �����ͺ��̽� ���� ��ü�� ���ڷμ�

	// ���������� db���� ȸ������ �ҷ����ų� db�� ȸ������ ������

	private Connection conn; // connection:db�������ϰ� ���ִ� ��ü
	private PreparedStatement pstmt;
	private ResultSet rs;

	// mysql�� ������ �ִ� �κ�

	public WriteDAO() {
		try {
			conn = DBUtil.getConnection();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
		
		public int write(User user) {

			String SQL = "INSERT INTO test.write VALUES (?,?,?,sysdate)";

			try {

				pstmt = conn.prepareStatement(SQL);
				pstmt.setString(1, user.getTrip());
				pstmt.setString(2, user.getTitle());
				pstmt.setString(3, user.getMemo());

				return pstmt.executeUpdate();

			} catch (Exception e) {

				e.printStackTrace();

			}

			return -1; // DB ����

	}
}