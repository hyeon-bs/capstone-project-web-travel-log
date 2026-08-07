package db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.util.Properties;

public class DBUtil {

    private static final String URL;
    private static final String USER;
    private static final String PASS;

    static {
        Properties p = new Properties();
        try {
            p.load(DBUtil.class.getClassLoader().getResourceAsStream("db.properties"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        URL  = p.getProperty("db.url");
        USER = p.getProperty("db.user");
        PASS = p.getProperty("db.password");
    }

    public static Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(URL, USER, PASS);
    }
}
