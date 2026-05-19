package user;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class WriteDAO {
	// dao : 데이터베이스 접근 객체의 약자로서

	// 실질적으로 db에서 회원정보 불러오거나 db에 회원정보 넣을때

	private Connection conn; // connection:db에접근하게 해주는 객체
	private PreparedStatement pstmt;
	private ResultSet rs;

	// mysql에 접속해 주는 부분

	public WriteDAO() { // 생성자 실행될때마다 자동으로 db연결이 이루어 질 수 있도록함

		try {

			String dbURL = "jdbc:mysql://localhost:3306/test"
					+ ""; // localhost:3306 포트는 컴퓨터설치된 mysql주소
			String dbID = "root";
			String dbPassword = "20163291";
			Class.forName("com.mysql.jdbc.Driver");

			conn = DriverManager.getConnection(dbURL, dbID, dbPassword);

		} catch (Exception e) {
			e.printStackTrace(); // 오류가 무엇인지 출력
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

			return -1; // DB 오류

	}
}