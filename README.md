# 웹 여행일지 (Web Travel Diary)

> 동의대학교 컴퓨터소프트웨어공학과 캡스톤 디자인 졸업작품


https://github.com/user-attachments/assets/4ab15f20-7c30-4f89-8175-2987a774cdff



## 프로젝트 개요

여행 중 느낀 경험과 감정을 스스로 기록하고 되돌아볼 수 있는 개인 다이어리형 웹 애플리케이션입니다.
Apache Tomcat 서버 환경에서 JSP와 MySQL을 연동하고 JDBC 및 DAO 패턴을 활용하여 안정적인 데이터 CRUD 시스템을 구축했습니다. 로그인 기반의 비공개 기록 공간을 제공하여 사용자가 보여주기식 SNS가 아닌 자신만의 내면을 기록하고 되새길 수 있도록 설계했습니다.

## 프로젝트 정보

| 항목 | 내용 |
|------|------|
| 기간 | 2019.10.01 ~ 2019.11.19 |
| 학교 | 동의대학교 컴퓨터소프트웨어공학과 |
| 유형 | 캡스톤 디자인 졸업작품 |

## 기술 스택

| 분류 | 기술 |
|------|------|
| Language & Framework | Java, JSP |
| Database | MySQL, MySQL Workbench |
| Server | Apache Tomcat |
| Frontend | Bootstrap (CSS/JS) |
| Architecture | Model 1 Architecture, DAO Pattern |
| Design Patterns | Prototype Pattern, Observer Pattern |
| 개발 방법론 | Agile (Scrum) |

## 주요 기능

| 기능 | 설명 |
|------|------|
| 로그인 | MySQL SELECT 쿼리로 아이디/비밀번호 인증 |
| 회원가입 | 폼 입력 → MySQL INSERT → 중복 아이디 예외 처리 |
| 캘린더 | `SimpleDateFormat`으로 날짜 계산, 이전/다음 달 이동, 날짜 클릭 시 글쓰기 이동 |
| 게시판 (여행일지) | 여행지·제목·내용 작성 → MySQL UPDATE → 목록 조회 |

## 설계 패턴

### Prototype Pattern
`UserDAO`, `WriteDAO`에서 MySQL 연결 객체를 미리 생성해둔 후, `login()` · `sign_up()` · `write()` 등의 메서드 호출 시 해당 연결을 복사하여 인스턴스를 생성하는 방식으로 중복 코드를 줄였습니다.

### Observer Pattern
`sign_up()` · `write()` 에서 `executeQuery()` / `executeUpdate()` 실행 후 결과를 `ResultSet(rs)`에 담아 DB 테이블 갱신 여부를 시스템이 즉시 감지하도록 설계했습니다.

## 프로젝트 목적 및 내용

### 1. 캘린더 기반의 여행 데이터 관리 시스템 구축
사용자가 일자별로 여행 일정 데이터를 직관적으로 기록하고 관리할 수 있는 시스템을 구현했습니다.

#### 주요 관리 정보
- 사용자 인증 정보 (아이디, 비밀번호 등)
- 여행 일지 (여행지, 제목, 본문 내용)
- 기록 일자 (sysdate 기반 데이터 매핑)

### 2. JDBC 기반 데이터 접근 객체(DAO) 아키텍처 구현
데이터베이스 연동 전반을 처리하는 전용 객체를 설계하여 소스 코드의 독립성과 유지보수성을 높였습니다.

#### 주요 기능
- `PreparedStatement` 활용을 통한 SQL 선컴파일 및 보안성 강화
- `executeUpdate()` 및 `executeQuery()`를 통한 데이터 삽입·조회 분기 처리
- try-catch 예외 처리를 통한 시스템 안정성 확보 (오류 발생 시 고유 상태 코드 반환)

```java
/* 회원가입 데이터 삽입 처리 및 트랜잭션 수행 */
public int sign_up(User user) {
    String SQL = "INSERT INTO test.information VALUES (?,?,?,?,?,?)";
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
    return -1; // DB 오류 발생 시 상태 코드 반환
}
```

### 3. 자바스크립트를 활용한 웹 프론트엔드 유효성 및 예외 검증
JSP 비즈니스 로직(Action 페이지)단에서 데이터베이스 처리 결과값을 검증하고 상황에 맞는 클라이언트 알림 기능을 구현했습니다.

#### 예외 검증 기준
- **필수 필드 공란 발생 시:** 이전 페이지 리다이렉트 및 안내 팝업
- **회원가입 시 기본키(ID) 중복 발생 시:** 경고 문구 출력 및 입력 폼 유지
- **로그인 인증 성공 및 실패 시:** 데이터 매핑 결과에 따른 페이지 전환 제어

```java
<%-- 회원가입 결과에 따른 유효성 검증 및 페이지 포워딩 처리 --%>
<%
    UserDAO userDAO = new UserDAO();
    int result = userDAO.sign_up(user);

    if (result == -1) { // Primary Key 중복 예외 처리
        PrintWriter script = response.getWriter();
        script.println("<script>");
        script.println("alert('이미 존재하는 아이디 입니다.')");
        script.println("history.back()");
        script.println("<script>");
    } else { // 인증 및 등록 성공
        PrintWriter script = response.getWriter();
        script.println("<script>");
        script.println("location.href = 'main.jsp'");
        script.println("</script>");
    }
<%
```

## 주요 기능 및 코드 구조

### 1. 회원 관리 및 인증 시스템 (user)
#### `UserDAO.java`
- MySQL DBMS 서버 드라이버 로드 및 커넥션 풀 초기화
- 호스트 데이터 기반 로그인 인증 및 패스워드 일치 여부 검증
- `sign_up()` 메서드를 통한 신규 유저 데이터 적재

#### `sign_up_Action.jsp / login_Action.jsp`
- 사용자 입력 데이터 유효성 검증 로직 구현
- 자바스크립트(`PrintWriter`) 기반 흐름 제어 및 팝업 렌더링

### 2. 여행 일지 아카이빙 시스템 (write)
#### `WriteDAO.java`
- 여행 기록 및 캘린더 연동 쿼리 수행
- `sysdate` 함수를 이용한 작성 시점 타임스탬프 처리

#### `write_Action.jsp`
- 작성된 일지 데이터 유효성 체크 및 `Calendar.jsp`로의 리다이렉션 처리

## 실행 결과

### 로그인 화면
<img src="docs/static/로그인 화면.png" width="650" height="400" />
<img src="docs/static/로그인 팝업.png" width="650" height="400" />

사용자 인증을 진행하는 화면으로 아이디와 비밀번호 미일치 시 팝업을 통해 예외 원인을 안내합니다.

### 회원가입 및 데이터베이스 반영 화면
<img src="docs/static/회원가입 데이터베이스.png" height="100" />
<img src="docs/static/화원가입 화면.png" height="350" />

신규 회원 정보를 입력하는 폼 화면이며 가입 완료 시 MySQL DB에 정상적으로 데이터가 적재됨을 확인할 수 있습니다.

### 캘린더 메인 화면
<img src="docs/static/캘린더 화면.png" width="650" height="400" />

오늘의 날짜를 직관적으로 제공하며 일지 작성 및 게시판 이동 등의 핵심 허브 역할을 수행하는 메인 인터페이스입니다.

### 게시판 및 데이터 조회 화면
<img src="docs/static/게시판 데이터 베이스.png" width="650" height="100" />

데이터베이스에 저장된 게시물 리스트를 호출하여 화면에 렌더링하며 사용자가 작성한 여행 기록 데이터를 연동하여 보여줍니다.

## 프로젝트 문제점 및 한계

1. 초기 구현 단계에서 웹 애플리케이션 서버(`Tomcat`)와 외부 데이터베이스(`MySQL`) 간의 문자열 인코딩 규격이 일치하지 않아 데이터 왜곡(한글 깨짐) 현상이 발생했습니다.

2. 데이터베이스 접속 계정 정보(ID/PW)가 소스 코드 내에 하드코딩되어 있어 실제 서비스 환경 배포 시 보안 취약점 노출 우려가 있었습니다.

3. 팀 프로젝트로 기획되었으나 백엔드 데이터 처리 아키텍처 아웃라인 구성에 리소스가 집중되어 반응형 웹 가독성 등 UI/UX 디테일 확장에는 한계가 있었습니다.

## 수정 및 보완 사항

- **한글 깨짐 오류 해결:** DB 프로토콜 주소 및 JSP 최상단 템플릿에 명시적으로 UTF-8 인코딩 설정을 적용하여 Workbench 및 화면 단의 문자열 깨짐 문제를 완전히 해결했습니다.

- **보안성 고려:** 코드 내 적재되어 있던 로컬 DB 패스워드 등 민감한 자원 정보를 마스킹 처리하여 레포지토리 보안성을 확보했습니다.

- **비즈니스 로직 최적화:** 액션 페이지 내 복잡하게 얽혀 있던 유효성 검사 로직을 리팩토링하여 데이터 예외 처리 분기를 명확하게 고도화했습니다.

## 문서

- [졸업작품 결과보고서 (PDF)](docs/동의대-컴소졸업작품-결과보고서(웹%20여행일지).pdf)
