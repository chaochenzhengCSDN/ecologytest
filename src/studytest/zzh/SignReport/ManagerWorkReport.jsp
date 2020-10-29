<!-- 门店考勤月报表 -->
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="org.apache.commons.lang3.StringUtils"%>
<%@page import="weaver.conn.RecordSet"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@ page import="javax.persistence.Id" %>
<%@ page import="java.util.*" %>
<jsp:useBean id="BaseBean" class="weaver.general.BaseBean" scope="page" />
<jsp:useBean id="ResourceComInfo" class="weaver.hrm.resource.ResourceComInfo" scope="page" />
<%
	String month = Util.null2String(request.getParameter("month"));
	
	String result[] = month.split("-");
	String month2 = result[1];
	String year2 = result[0];
	int month3 = Integer.parseInt(month2);	
	int year3 = Integer.parseInt(year2);
	
	//获取日历类对象
	Calendar c = Calendar.getInstance();
	c.set(year3,month3-1,1);
	SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
	String checkMinDate = sdf.format(c.getTime());

	c.add(Calendar.MONTH,+1);
	c.add(Calendar.DATE,-1);
	String checkMaxDate = sdf.format(c.getTime());
	int maxDateDays = c.get(Calendar.DATE);
	int roll = maxDateDays+5;

	c.add(Calendar.MONTH,-1);
	String defaultStartDate = sdf.format(c.getTime());

	c.add(Calendar.MONTH,2);
	String defaultEndDate = sdf.format(c.getTime());


	BaseBean b = new BaseBean();
%> 
<head>
	<style type="text/css">
		#div1 td{
		  padding-top: 10px;
		  padding-bottom: 10px;
		}
		#div1{
			overflow: auto;
			width: 100%;
			height: calc(100vh - 170px);
		}
		#trr3{
			height: 120px;
		}
		#trr1{
			height: 35px;
		}
	</style>
</head>
<body>
<div id="div1">
	<table width="2000px" border="0" cellpadding="0" cellspacing="0">		
			<tr id="trr1">		
				<th align='center' width='100'>分部名称</th>
				<th align='center' width='100'>机构名称</th>
				<th align='center' width='80'>人员编号</th>
				<th align='center' width='80'>姓名</th>
				<th align='center' width='50'>月份</th>
				<!--获取当前最大天数，并进行遍历-->
				<%
					for(int k = 1;k<=maxDateDays;k++){
				%>
						<th align='center' width="50px"><%=k%></th>
				<%
					}
				%>
			
			</tr>
			<%
				//查询该用户对应的部门以及该部门的领导
				String departAndLeaderSql="select id,departmentid from ( select * from hrmresource where departmentid in " +
						" (select departmentid from hrmresource where id='"+user.getUID()+"')  ORDER BY seclevel desc) where  ROWNUM =1";
				RecordSet departAndLeaderRs=new RecordSet();
				departAndLeaderRs.executeSql(departAndLeaderSql);
				departAndLeaderRs.next();
				String leaderId=Util.null2String(departAndLeaderRs.getString("id"));
				String departmentId=Util.null2String(departAndLeaderRs.getString("departmentid"));
				b.writeLog(leaderId.equals(String.valueOf(user.getUID())));
				//查询该人员是否为部门领导以及部门是否对应
				if(leaderId.equals(String.valueOf(user.getUID()))){
					//项目总监 可以查询需求产品部129581 开发一部9619 开发二部9621 开发三部37079 开发四部129579 基础研发部129580 质量部129582的考勤人员 （包含自己）
                    String sql=new String();
					if("9341".equals(String.valueOf(user.getUID()))){
						sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname,hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType  FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid=hde.id where";
						sql+="  (hre.departmentid in (129581,9619,9621,37079,129579,129580,129582) or hre.id=9341) AND CASE WHEN hre.startdate is NULL THEN '"+defaultEndDate+"' ELSE hre.startdate END <= '"+defaultEndDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+defaultStartDate+"' ELSE hre.enddate END >= '"+defaultStartDate+"' and hre.accounttype !=1 ORDER BY hde.id,hsc.signDate ASC";
					}else if("5877".equals(String.valueOf(user.getUID()))){
					//开发二部经理兼质量部经理 可以查询需求开发二部9621 质量部129582的考勤人员
						sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname,hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType  FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid=hde.id where";
						sql+="  (hre.departmentid in (9621,129582) or hre.id=9341) AND CASE WHEN hre.startdate is NULL THEN '"+defaultEndDate+"' ELSE hre.startdate END <= '"+defaultEndDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+defaultStartDate+"' ELSE hre.enddate END >= '"+defaultStartDate+"' and hre.accounttype !=1 ORDER BY hde.id,hsc.signDate ASC";
					}else{
						sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname,hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType  FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid=hde.id where";
						sql+=" EXISTS (SELECT 1 FROM hrmdepartment WHERE id in ( "+user.getUserDepartment()+" ) AND id = hre.departmentid) AND";
						sql+=" hre.subcompanyid1 in(select id from hrmsubcompany start with id = 761 connect by prior  id = supsubcomid) AND CASE WHEN hre.startdate is NULL THEN '"+defaultEndDate+"' ELSE hre.startdate END <= '"+defaultEndDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+defaultStartDate+"' ELSE hre.enddate END >= '"+defaultStartDate+"' and hre.accounttype !=1 ORDER BY hde.id,hsc.signDate ASC";
					}
					b.writeLog("sql:"+sql);
					//定义集合，把数据进行封装
					Map<String,Map<String, List<String>>> areaResult = getAreaResult(sql);
					//判断获取的数据是否为空
					if(areaResult!=null && areaResult.size()>0){
						//获取结果集所有键的集合，用keySet()方法实现
						Set<String> keySet = areaResult.keySet();
						//遍历键的集合，获取到每一个键。用增强for实现
						for (String key : keySet) {
							String subcompanyname = key.split(",")[0];
							String departmentname = key.split(",")[1];
							String workCode = key.split(",")[2];
							String lastname = key.split(",")[3];
							out.println("<tr id='trr3'>");
							out.println("<td align='center'>"+subcompanyname+"</td>");
							out.println("<td align='center'>"+departmentname+"</td>");
							out.println("<td align='center'>"+workCode+"</td>");
							out.println("<td align='center'>"+lastname+"</td>");
							out.println("<td align='center'>"+month3+"</td>");
							
							//根据键去找值，用get(Object key)方法实现
							Map<String,List<String>> value = areaResult.get(key);
							//判断value集合是否为空
							if(value.size()>0){
								//获取结果集所有键的集合，用keySet()方法实现
								Set<String> valueSet = value.keySet();
								//调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
								TreeSet<String> ts1 = getDateTreeSet();
								ts1.addAll(valueSet);
								//定义一个初始值
								int day = 0;
								//遍历键的集合，获取到每一个键。用增强for实现
								for (String key1 : ts1) {
									String day1 = key1.split("-")[2];
									int day2 = Integer.parseInt(day1);
									//根据键去找值，用get(Object key)方法实现
									List<String> timeList = value.get(key1);
									//调用getTimeTreeSet()方法对HH:mm:ss格式时间进行排序
									TreeSet<String> ts2 = getTimeTreeSet();
									//for循环遍历timeList集合
									for(int i = 0;i < timeList.size();i++){
										String s = timeList.get(i);
										ts2.add(s);
									}
									//遍历得到第一个天数，减去初始值，然后循环这个天数减去初始值得到结果的数量的td标签
									for(int j = 1;j < day2-day;j++){
										out.println("<td>");
										out.println("</td>");
									}
									//把遍历得到的第一个天数赋值给初始值
									day=day2;
									out.println("<td>");
									
									//调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
									List<String> morningTimeList = getMorningTimeList(ts2);
									
									//调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
									List<String> afternoonTimeList = getAfternoonTimeList(ts2);
									
									//调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
									List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);
									
									//调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
									List<String> finalTimeList = getFinalTimeList(morningTimeList,afternoonTimeList,confirmTimeList);
									
									//遍历最终打卡时间集合
									for (String time : finalTimeList) {
										out.println("<p>"+time.substring(0,5)+"</p>");
									}
									out.println("</td>");
								}
								//当前月的天数减去最后一次获取的天数，然后循环td标签，补全表格
								for(int i = 1;i<=(maxDateDays-day);i++){
									out.println("<td>");
									out.println("</td>");
								}
							}else{
								//为空则打印空行
								for(int i = 1;i<=maxDateDays;i++){
									out.println("<td>");
									out.println("</td>");
								}
							}
						}
						out.println("</tr>");						
					}else{
						//为空则输出无查询结果
						out.println("<tr>");
						out.println("<td colspan='"+roll+"' style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center'>无查询结果，请确认查询报表条件</td>");
						out.println("</tr>");
					}
				}else{
					out.println("<tr>");
					out.println("<td colspan='"+roll+"' style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center'>无权限查询</td>");
					out.println("</tr>");
				}
				%>
<!-- 获取时间的秒数getTime(String s) -->			
<%!
	public static Integer getTime(String s){
		String [] arr = s.split(":");
		int hour = Integer.parseInt(arr[0]);
		int minute = Integer.parseInt(arr[1]);
		int seconds = Integer.parseInt(arr[2]);
		return hour*3600+minute*60+seconds;
	}
%>

<!-- 对HH:mm:ss格式时间进行排序getTimeTreeSet() -->
<%!
	public static TreeSet<String> getTimeTreeSet(){
		//创建TreeSet集合对象
		TreeSet<String> ts = new TreeSet<String>(new Comparator<String>() {
			public int compare(String s1, String s2) {
				String [] split1 = s1.split(":");
				int s11 = Integer.parseInt(split1[0]);
				int s12 = Integer.parseInt(split1[1]);
				int s13 = Integer.parseInt(split1[2]);
				String [] split2 = s2.split(":");
				int s21 = Integer.parseInt(split2[0]);
				int s22 = Integer.parseInt(split2[1]);
				int s23 = Integer.parseInt(split2[2]);

				int num = s11-s21;
				int num2 = num == 0 ? s12 - s22:num;
				int num3 = num2 == 0 ? s13 - s23 : num2;
				return num3;
			}
		});
		return ts;
	}
%>

<!-- 对yyyy-MM-dd格式日期进行排序getDateTreeSet() -->
<%!
	public static TreeSet<String> getDateTreeSet(){
		TreeSet<String> ts = new TreeSet<String>(new Comparator<String>() {
			public int compare(String s1, String s2) {
				String[] split = s1.split("-");
				int i1 = Integer.parseInt(split[2]);
				String[] split2 = s2.split("-");
				int i2 = Integer.parseInt(split2[2]);
				int num = i1-i2;
				return num;
			}
		});
		return ts;
	}
%>

<!-- 获取从数据库查询到的数据进行封装getAreaResult(String sql) -->
<%!	
	public static Map<String,Map<String,List<String>>> getAreaResult(String sql){
		RecordSet rs = new RecordSet();	
		rs.executeSql(sql);
		//定义集合，把数据进行封装
		Map<String,Map<String,List<String>>> areaResult = new LinkedHashMap<String,Map<String,List<String>>>();		
		while(rs.next()) {	
			//分部名称
			String subcompanyname = Util.null2String(rs.getString("subcompanyname"));	
			//机构名称
			String departmentname = Util.null2String(rs.getString("departmentname"));
			//人员编号
			String workCode = Util.null2String(rs.getString("workCode"));
			//姓名
			String lastname = Util.null2String(rs.getString("lastname"));
			//考勤日期
			String signDate = Util.null2String(rs.getString("signDate"));
			//考勤时间
			String signTime = Util.null2String(rs.getString("signTime"));
			//考勤类型
			String signType = Util.null2String(rs.getString("signType"));
			//应出勤
			String days = Util.null2String(rs.getString("days"));
			//法定节假日
			String holiday = Util.null2String(rs.getString("holiday"));
			if(!signTime.isEmpty() && signTime!=null && !signType.isEmpty() && signType!=null){
				signTime  = signTime + ":" + signType;
			}
			//定义集合的key值
			String key = subcompanyname+","+departmentname+","+workCode+","+lastname;
			
			//判断是否是同一个人
			if(areaResult.containsKey(key)){
				//判断是否是同一天
				if(areaResult.get(key).containsKey(signDate)){			
					areaResult.get(key).get(signDate).add(signTime);
				}else{
					List<String> timeList1 =new ArrayList<String>();
					timeList1.add(signTime);
					areaResult.get(key).put(signDate,timeList1);
				}
			}else{	
				Map<String,List<String>> areaResult1= new HashMap<String,List<String>>();
				List<String> timeList2 =new ArrayList<String>();
				if(!signTime.isEmpty() && signTime!=null && !signDate.isEmpty() && signDate!=null){
					timeList2.add(signTime);	
					areaResult1.put(signDate,timeList2);
					areaResult.put(key,areaResult1);	
				}else{
					areaResult.put(key,areaResult1);
				}
			}
		}
		return areaResult;
	}
%> 

<!-- 获取上午时段的打卡时间 -->
<%!
	public static List<String> getMorningTimeList(TreeSet<String> ts){
		//定义第一个集合，添加上午时段的打卡时间
		List<String> morningTimeList = new ArrayList<String>();
		//定义第二个集合，添加上午时段的上班卡时间
		List<String> morningUpTimeList = new ArrayList<String>();
		//定义第三个集合，添加上午时段的下班卡时间
		List<String> morningDownTimeList = new ArrayList<String>();
		//定义第四个集合，把set集合转为list集合
		List<String> list = new ArrayList<String>(ts);
		for(int l = 0;l<list.size();l++){
			String time = list.get(l);
			String [] split1 = time.split(":");
			int hour = Integer.parseInt(split1[0]);
			int minute = Integer.parseInt(split1[1]);
			int seconds = Integer.parseInt(split1[2]);
			int typeInt = Integer.parseInt(split1[3]);
			if(0<=hour && hour<12 && 0<=minute && minute<60 && 0<=seconds && seconds<60){
				if(typeInt==1){
					morningUpTimeList.add(time);
				}else if(typeInt==2){
					morningDownTimeList.add(time);
				}
			}
		}
		if(morningUpTimeList.size()>0){
			//获取上午上班卡最早的一个打卡时间
			String time = morningUpTimeList.get(0);
			morningTimeList.add(time);
		}
		if(morningDownTimeList.size()>0){
			//获取上午下班卡最晚的一个打卡时间
			String time = morningDownTimeList.get((morningDownTimeList.size())-1);
			morningTimeList.add(time);
		}
		return morningTimeList;
	}
%>

<!-- 获取下午时段的打卡时间 -->
<%!
	public static List<String> getAfternoonTimeList(TreeSet<String> ts){
		//定义第一个集合，添加下午时段的打卡时间
		List<String> afternoonTimeList = new ArrayList<String>();
		//定义第二个集合，添加下午时段的上班卡时间
		List<String> afternoonUpTimeList = new ArrayList<String>();
		//定义第三个集合，添加下午时段的下班卡时间
		List<String> afternoonDownTimeList = new ArrayList<String>();
		//定义第四个集合，把set集合转为list集合
		List<String> list = new ArrayList<String>(ts);
		for(int l = 0;l<list.size();l++){
			String time = list.get(l);
			String [] split1 = time.split(":");
			int hour = Integer.parseInt(split1[0]);
			int minute = Integer.parseInt(split1[1]);
			int seconds = Integer.parseInt(split1[2]);
			int typeInt = Integer.parseInt(split1[3]);
			if(12<=hour && hour<24 && 0<=minute && minute<60 && 0<=seconds && seconds<60){
				if(typeInt==1){
					afternoonUpTimeList.add(time);
				}else if(typeInt==2){
					afternoonDownTimeList.add(time);
				}
			}
		}
		if(afternoonUpTimeList.size()>0){
			//获取下午上班卡最早的一个打卡时间
			String time = afternoonUpTimeList.get(0);
			afternoonTimeList.add(time);
		}
		if(afternoonDownTimeList.size()>0){
			//遍历下午下班卡
			for(int d = 0;d<afternoonDownTimeList.size();d++){
				String time = afternoonDownTimeList.get(d);
				afternoonTimeList.add(time);	
			}
		}
		return afternoonTimeList;
	}
%>

<!-- 获取下午17:15时段之后的打卡时间 -->
<%!
	public static List<String> getConfirmTimeList(List<String> afternoonTimeList){
		List<String> confirmTimeList = new ArrayList<String>();
		for(int y = 0;y<afternoonTimeList.size();y++){
			String time = afternoonTimeList.get(y);
			String [] split1 = time.split(":");
			int hour = Integer.parseInt(split1[0]);
			int minute = Integer.parseInt(split1[1]);
			int seconds = Integer.parseInt(split1[2]);
			int typeInt = Integer.parseInt(split1[3]);
			if((y==0 && typeInt==1) || (y==0 && afternoonTimeList.size()==1)){
				
			}else{
				if((hour>17) || (hour==17 && minute>=15 && seconds<60 && seconds>=0)){
					confirmTimeList.add(time);
				}
			}
		}
		return confirmTimeList;
	}
%>

<!-- 获取下午17:15时段之前的最终打卡时间 -->
<%!
	public static List<String> getFinalAfternoonTimeList(List<String> afternoonTimeList){
		//定义下午17:15时段之前的最终打卡时间的集合
		List<String> finalAfternoonTimeList = new ArrayList<String>();
		for(int y = 0;y<afternoonTimeList.size();y++){
			String time = afternoonTimeList.get(y);
			String [] split1 = time.split(":");
			int hour = Integer.parseInt(split1[0]);
			int minute = Integer.parseInt(split1[1]);
			int seconds = Integer.parseInt(split1[2]);
			int typeInt = Integer.parseInt(split1[3]);
			//1.2如果最后一次打卡在17:15:00之前，则取17:15:00之前的第一次打卡时间和最后一次打卡时间
			if((afternoonTimeList.size())>1 && y==(afternoonTimeList.size()-1) && ((hour<17) || (hour==17 && minute<15 && seconds<60))){
				String time2 = afternoonTimeList.get(y);
				finalAfternoonTimeList.add(time2);
			//1.3如果最后一次打卡在17:15:00之后则取下午时段的第一次打卡的时间和17:15:00之后打卡的时间
			}
			if((y==0 && typeInt==1) || (y==0 && afternoonTimeList.size()==1)){
				finalAfternoonTimeList.add(time);
			}	
		}
		return finalAfternoonTimeList;
	}
%>

<!-- 获取下午17:15时段之后的最终打卡时间 -->
<%!
	public static List<String> getFinalCofirmTimeList(List<String> confirmTimeList){
		//定义下午17:15时段之后的最终打卡时间的集合
		List<String> finalCofirmTimeList = new ArrayList<String>();
		//1.如果17:15:00之后的时间集合里只有一个数据，那就直接展示
		if(confirmTimeList.size()==1){
			String time = confirmTimeList.get(0);
			finalCofirmTimeList.add(time);
		}
		
		//2.如果17:15:00之后的时间集合里有两个数据，判断这两个数据是否相差30分钟
		if(confirmTimeList.size()==2){
			String time1 = confirmTimeList.get(0);
			int secondsTime1 = getTime(time1);
			String time2 = confirmTimeList.get(1);
			int secondsTime2 = getTime(time2);
			//2.1如果相差30分钟，则把这两个数据都展示出来
			if(secondsTime2-secondsTime1>=1800){
				finalCofirmTimeList.add(time1);
				finalCofirmTimeList.add(time2);
			}else{
				//2.2如果不相差30分钟，则把最后一个数据展示出来
				finalCofirmTimeList.add(time2);
			}											
		}

		List<String> countList = new ArrayList<String>();
		//3.如果17:15:00之后的时间集合里有超过两个数据的
		if(confirmTimeList.size() > 2){
			for(int z = 0;z<confirmTimeList.size();z++){
				if (z==0){
					String time = confirmTimeList.get(z);
					countList.add(time);
				}else {
					if (finalCofirmTimeList.size() < 3) {
						//3.1先取第一次打卡记录
						String time1 = confirmTimeList.get(z-1);
						String time2 = confirmTimeList.get(z);
						int secondsTime1 = getTime(time1);
						int secondsTime2 = getTime(time2);
						//3.2若存在30分钟后的打卡记录，则取第一次和30分钟后第一次的打卡记录
						if (secondsTime2 - secondsTime1 >= 1800) {
							String time = confirmTimeList.get(0);
							finalCofirmTimeList.add(time);
							finalCofirmTimeList.add(time2);
							countList.add(time2);
							if (confirmTimeList.size()-(z+1)>0){
								String time3 = confirmTimeList.get(confirmTimeList.size() - 1);
								finalCofirmTimeList.add(time3);
								countList.add(time3);
							}
						} else {
							//3.3若不存在30分钟后的打卡记录，则取最后一次的打卡记录
							if (z == (confirmTimeList.size() - 1) && countList.size()==1){
								String time3 = confirmTimeList.get(confirmTimeList.size() - 1);
								finalCofirmTimeList.add(time3);
							}
						}
					}
				}
			}
		}
		return finalCofirmTimeList;
	}
%>

<!-- 获取最终的打卡时间 -->
<%!
public static List<String> getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList){
	List<String> finalTimeList = new ArrayList<String>();
	//遍历上午时段的打卡集合
	for(int x = 0;x<morningTimeList.size();x++){
		String time = morningTimeList.get(x);
		finalTimeList.add(time);
	}
	//遍历下午17:15时段之前的最终打卡集合
	List<String> finalAfternoonTimeList = getFinalAfternoonTimeList(afternoonTimeList);
	for(int y = 0;y<finalAfternoonTimeList.size();y++){
		String time = finalAfternoonTimeList.get(y);
		finalTimeList.add(time);
	}

	//遍历下午时段17:15:00之后的时间集合
	List<String> finalCofirmTimeList = getFinalCofirmTimeList(confirmTimeList);
	for(int y = 0;y<finalCofirmTimeList.size();y++){
		String time = finalCofirmTimeList.get(y);
		finalTimeList.add(time);
	}
	return finalTimeList;
}
%>
	</table>
</div>
</body>