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
	String titlename = "员工出差明细表";
	BaseBean b = new BaseBean();
	DepartmentComInfo departmentComInfo = new DepartmentComInfo();
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
			String mobileSignSql ="select * from mobile_sign where operater = '" + userId + "' and operate_date like '%" + month + "%' order by operate_date,operate_time asc";
			RecordSet mobileSignRs=new RecordSet();
			mobileSignRs.executeSql(mobileSignSql);
			//b.writeLog("业务考勤打卡数据sql查询为："+mobileSignSql);
			List<String> mobileSignList=new LinkedList<String>();
			Map<String,String> map = new HashMap<String,String>();
			//将业务考勤打卡记录查出并存储到集合中
			while (mobileSignRs.next()){
			   String mobileSignDate= mobileSignRs.getString("operate_date");
				mobileSignList.add(mobileSignDate);
				String address= mobileSignRs.getString("address");
				map.put(mobileSignDate,address);
			}
			//b.writeLog("业务考勤当月打卡集合："+mobileSignList);
			//b.writeLog("考勤地点Map："+map);
			String businessTripSql="select * from uf_businesstrip  where userid='"+userId+"' and  (start_date like '%"+month+"%' or end_date like '%"+month+"%') order by start_date,start_time asc";
			RecordSet businessTripRs=new RecordSet();
			businessTripRs.executeSql(businessTripSql);
			//b.writeLog("出差流程申请sql语句:"+businessTripSql);
			List<String> recordList = new LinkedList<String>();
			while(businessTripRs.next()){
			    String company=businessTripRs.getString("company");//公司名称
			    int depart=businessTripRs.getInt("depart");
			    String departSql ="select departmentname from hrmdepartment where id="+depart+"";
			    String departname=getName(departSql,"OA");//部门名称
			    String userid=businessTripRs.getString("userid");
			    String getLastNameSql ="select lastname from hrmresource where id='"+userid+"'";
			    String lastName=getName(getLastNameSql,"OA");//姓名
			    String startTime=businessTripRs.getString("start_time");//开始时间
			    String endTime=businessTripRs.getString("end_time");//结束时间
				String newEndTime=endTime;//用于接收的原来的endTime
				//b.writeLog(newEndTime);
			    String startDate=businessTripRs.getString("start_date");//开始日期
				String newstartDate=startDate;
			    String endDate=businessTripRs.getString("end_date");//结束日期
				String newEndDate=endDate;
				String travelLocation=businessTripRs.getString("travellocation");//出差地点
				//集合中包含开始日期/结束日期，不需要可去除
				List<String> list = new ArrayList<String>();
				try {
					SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
					long s = Long.valueOf(sdf.parse(startDate).getTime());
					long e = Long.valueOf(sdf.parse(endDate).getTime());
					//只有结束时间大于开始时间时才进行查询
					if(s<=e) {
						list = findDates(startDate, endDate);
					}
				} catch (ParseException e) {
					e.printStackTrace();
				}
				//b.writeLog("出差日期的集合："+list);
				//if(!startDate.equals(endDate)){
					for(String time : list) {
						//查询当前申请包含的所有的日期， 查看是否有业务考勤打卡数据
						if(mobileSignList.contains(time)){
							//如果出差开始日期有业务考勤
							//b.writeLog(time+"<<<>>>"+endDate);
							if(time.equals(newstartDate)&&time.equals(newEndDate)){//当日
								//b.writeLog("请假时间为当天");
							}else if(time.equals(newstartDate)&&!time.equals(newEndDate)){ //起始日
								startDate =time;
								endDate =time;
								endTime ="23:59";
							}else if(!time.equals(newstartDate)&&time.equals(newEndDate)){//结束日
								startDate =time;
								endDate =time;
								startTime ="00:00";
								endTime =newEndTime;
							}else{//中间日
								startDate =time;
								endDate =time;
								startTime ="00:00";
								endTime ="23:59";
							}
							//b.writeLog("开始日期:"+startDate+";开始时间:"+startTime+";结束日期:"+endDate+";结束时间:"+endTime);
							String record =company+","+departname+","+lastName+","+startDate+","+startTime+","+endDate+","+endTime+","+travelLocation+","+map.get(time);
							recordList.add(record);
						}
					}
				//}else {
					//String record =company+","+departname+","+lastName+","+startDate+","+startTime+","+endDate+","+endTime+","+travelLocation;
					//recordList.add(record);
				//}
			}
			//b.writeLog("含有业务考勤打卡记录的集合："+recordList);
			if(recordList.size()>0){
			%>
			<tr>		
				<th align='center'>公司</th>
				<th align='center'>部门</th>
				<th align='center'>申请人姓名</th>
				<th align='center'>出差开始日期</th>
				<th align='center'>出差开始时间</th>
				<th align='center'>出差结束日期</th>
				<th align='center'>出差结束时间</th>
				<th align='center'>考勤地点</th>
				<th align='center'>实际出差地点</th>
			</tr>
			<%
			   	for(String record:recordList){
  					out.println("<tr>");
					out.println("<td align='center'>"+record.split(",")[0]+"</td>");
					out.println("<td align='center'>"+record.split(",")[1]+"</td>");
					out.println("<td align='center'>"+record.split(",")[2]+"</td>");
					out.println("<td align='center'>"+record.split(",")[3]+"</td>");
					out.println("<td align='center'>"+record.split(",")[4]+"</td>");
					out.println("<td align='center'>"+record.split(",")[5]+"</td>");
					out.println("<td align='center'>"+record.split(",")[6]+"</td>");
					out.println("<td align='center'>"+record.split(",")[7]+"</td>");
					out.println("<td align='center'>"+record.split(",")[8]+"</td>");
					out.println("</tr>");
 				}
			}else{
				out.println("<tr>");
				out.println("<th colspan='9' style='font-size:18px;height:80px;' align='center'>无查询结果，请确认查询报表条件</td>");
				out.println("</tr>");
			}
			%>
			<!--查询单结果为string对应的名称-->
			<%!
				public static String getName(String sql, String DateSource) throws Exception {
					RecordSet recordSet = new RecordSet();
					recordSet.executeSql(sql, DateSource);
					recordSet.next();
					String name = recordSet.getString(1);
					return name;
				}
			%>
			<!--查询出开始日期到结束日期包含的日期-->
			<%!
				public static List<String> findDates(String stime, String etime)
						throws ParseException {
					List<String> allDate = new ArrayList();
					SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

					Date dBegin = sdf.parse(stime);
					Date dEnd = sdf.parse(etime);
					allDate.add(sdf.format(dBegin));
					Calendar calBegin = Calendar.getInstance();
					// 使用给定的 Date 设置此 Calendar 的时间
					calBegin.setTime(dBegin);
					Calendar calEnd = Calendar.getInstance();
					// 使用给定的 Date 设置此 Calendar 的时间
					calEnd.setTime(dEnd);
					// 测试此日期是否在指定日期之后
					while (dEnd.after(calBegin.getTime())) {
						// 根据日历的规则，为给定的日历字段添加或减去指定的时间量
						calBegin.add(Calendar.DAY_OF_MONTH, 1);
						allDate.add(sdf.format(calBegin.getTime()));
					}
					return allDate;
				}
			%>
		</table>
	</body>
</html>
