<!-- 用户打卡明细表 -->
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ include file="/hrm/header.jsp" %>
<%@ page import="weaver.general.Util"%>
<%@ page import="weaver.iiot.studytest.bzt.utils.DisassembleUtil" %>
<%@ page import="weaver.hrm.company.DepartmentComInfo" %>
<%@ page import="weaver.conn.RecordSet" %>

<jsp:useBean id="BaseBean" class="weaver.general.BaseBean" scope="page" />
<%
	String userId = Util.null2String(request.getParameter("userId"));
	String month = Util.null2String(request.getParameter("month"));
	String imagefilename = "/images/hdReport_wev8.gif", needfav = "1", needhelp = "";
	String titlename = "员工加班明细表";
	BaseBean b = new BaseBean();
	DepartmentComInfo departmentComInfo = new DepartmentComInfo();  //测试服上为部门id,正式服上为中文，不同步
%> 
<style type="text/css">
*{
	margin: 0;
	padding: 0;
	border: 0;
	list-style-type: none;
	font-size: 11px;
}
td,th{
	border: 1px solid #90BADD;	
	height: 30px;
	text-align: center;
}
th{
	font-weight: bold;
}
.btn{
	height:30px;
	width: 1100px;
	border: 1px solid black;
	background-color: white;
}
#tablecontainer,#tablecontainer1{ 
	width: 100%; 
	height: 400px; 
	margin: 0 auto; 
}
body{
	position:relative;
}
.rightSearchSpan{
	position:absolute;
	right:50px;
	top:5px;
}
.e8_btn_top_a:hover{
	color:#FFFFFF !important;
	background-color:#03a996;
}
.e8_btn_top_a{
	border:1px solid #aecef1;
	color:#1098ff !important;
	background-color:#FFF;
	padding:2px 5px ;
}
</style>
<html>
	<head>
		<LINK href="/css/Weaver_wev8.css" type=text/css rel=STYLESHEET>
		<SCRIPT language="javascript" src="/js/weaver_wev8.js"></script>
		<SCRIPT language="javascript" src="/js/hrm/HrmTools_wev8.js"></script>

	</head>
	<body>
		<%@ include file="/systeminfo/TopTitle_wev8.jsp" %>
		<%@ include file="/systeminfo/RightClickMenuConent_wev8.jsp" %>
		<%@ include file="/systeminfo/RightClickMenu_wev8.jsp" %>		
		<table style="width:95%;margin:2%;" border="0" cellpadding="0" cellspacing="0">			
			<%
			 DisassembleUtil util =  new DisassembleUtil();
             Map<String, String> tableDataMap = new HashMap();
             ArrayList<Map<String, String>> myDetailList = new ArrayList();
			 RecordSet detail_rs = new RecordSet();
			 RecordSet rs_sys_user = new RecordSet();

			 //查询加班明细
             String detailSql = " select tt.*, "+
			"（case when tt.BREAK_OFF=0 then '是' else '否' end）as BREAKOFF,"+
	        "（case "+
			" when tt.OVERTIME_TYPE = 0 then "+
			" '正常工作日' "+ 
			" when tt.OVERTIME_TYPE = 1 then "+
			" '非工作日及法定假日' "+
			" when tt.OVERTIME_TYPE = 2 then "+
			" '晨会' "+
			" when tt.OVERTIME_TYPE = 3 then "+
			" '出差' else '正常加班' end）AS overtimetype "+
			" from UF_WORKOVERTIME tt where userid ='" + userId + "'"+
			" AND to_number(to_char(to_date(tt.WORK_DATE,'yyyy-mm-dd'),'yyyymm'))  = to_number(to_char(to_date('" + month + "-01','yyyy-mm-dd'),'yyyymm'))"+
			" order by work_date asc ";
			b.writeLog("加班明细:"+detailSql);
			 String userSql = "SELECT * FROM hrmResource where id='"+userId+"'";
			 try {
			             detail_rs.executeSql(detailSql);
                        myDetailList = util.disassembleTableDataMapList(detail_rs);
						rs_sys_user.executeSql(userSql);
						tableDataMap = util.disassembleTableDataMap(rs_sys_user);
                     } catch (Exception e) {
                        b.writeLog(e.getLocalizedMessage());
                    }
 			if(myDetailList != null && myDetailList.size()>0){	
			%>
			<tr>		
				<th align='center'>公司</th>
				<th align='center'>部门</th>
				<th align='center'>姓名</th>
				<th align='center'>加班时长</th>
				<th align='center'>加班类型</th>
				<th align='center'>加班日期</th>
				<th align='center'>开始时间</th>
				<th align='center'>结束时间</th>
				<th align='center'>是否调休</th>
			</tr>
			<%
			   for (Map<String, String> detail : myDetailList) {	
 					out.println("<tr>");
					out.println("<td align='center'>"+util.getFiled(detail,"company")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"depart")+"</td>");//正式环境
				    //out.println("<td align='center'>"+departmentComInfo.getDepartmentname(util.getFiled(detail,"depart"))+"</td>");//测试环境
				    out.println("<td align='center'>"+util.getFiled(tableDataMap,"lastname")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"overtime_hours")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"overtimetype")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"work_date")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"start_time")+"</td>");	
					out.println("<td align='center'>"+util.getFiled(detail,"end_time")+"</td>");
					out.println("<td align='center'>"+util.getFiled(detail,"breakoff")+"</td>");
					out.println("</tr>");
 				}
			}else{
				out.println("<tr>");
				out.println("<th colspan='9' style='font-size:18px;height:80px;' align='center'>无查询结果，请确认查询报表条件</td>");
				out.println("</tr>");
			}
			%>
		</table>
	</body>
</html>
