<!-- 门店考勤月报表 -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="weaver.conn.RecordSet" %>
<%@page import="weaver.iiot.grouptow.common.AbnormalCommonController" %>
<%@page import="weaver.iiot.grouptow.common.BusinessCommonController" %>
<%@page import="weaver.iiot.grouptow.common.FinalTimeListController" %>
<%@ page import="weaver.iiot.grouptow.common.LeaveCommonController" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.ParseException" %>
<%@ page import="java.text.SimpleDateFormat" %>
<jsp:useBean id="BaseBean" class="weaver.general.BaseBean"/>
<jsp:useBean id="ResourceComInfo" class="weaver.hrm.resource.ResourceComInfo"/>
<%

    // 日志输出
    BaseBean b = new BaseBean();
    // 功能组件
    String month = Util.null2String(request.getParameter("month"));
    //获取员工编号
    String userId = Util.null2String(request.getParameter("userId"));

    String[] result = month.split("-");
    String month2 = result[1];
    String year2 = result[0];
    int month3 = Integer.parseInt(month2);
    int year3 = Integer.parseInt(year2);

    //获取日历类对象
    Calendar c = Calendar.getInstance();
    c.set(year3,month3-1,1);
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    String checkMinDate = sdf.format(c.getTime());
    String likeDate = checkMinDate.substring(0,7);

    c.add(Calendar.MONTH,+1);
    c.add(Calendar.DATE,-1);
    String checkMaxDate = sdf.format(c.getTime());
    int maxDateDays = c.get(Calendar.DATE);
    int roll = maxDateDays+5;
%>

<head>
    <style type="text/css">
        #div1 td {
            padding-top: 10px;
            padding-bottom: 10px;
        }

        #div1 {
            overflow: auto;
            width: 100%;
            height: calc(100vh - 170px);
        }

        #trr1 {
            height: 35px;
        }
        td,th{
            border: 1px solid #90BADD;
            height: 30px;

            text-align: center;
        }
        th{
            font-weight: bold;
        }
        td{
            padding-top: 10px;
            padding-bottom: 10px;
        }
    </style>
</head>

<body>
<div id="div1">
    <table width="2000px" border="1px solid #90BADD" cellpadding="0" cellspacing="0">
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
            LeaveCommonController leaveCommonController=new LeaveCommonController();
            AbnormalCommonController abnormalCommonController=new AbnormalCommonController();
            BusinessCommonController businessCommonController=new BusinessCommonController();
            FinalTimeListController finalTimeListController=new FinalTimeListController();
            List<String> abnormalList=new LinkedList<String>();
            //查询当月应出勤日期 周一至周五
            List<String> curdateList = new ArrayList<String>();
            List<String> curdateList1 = new ArrayList<String>();//用于接收当前日期存在打卡记录的集合
            String curdateSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and ATTENDANCESTATUS=0";
            RecordSet rs6 = new RecordSet();
            rs6.execute(curdateSql);
            while (rs6.next()) {
                String curdate = rs6.getString(1);
                curdateList.add(curdate);
            }
            //查询当月应出勤日期 周六  //2020.04.19 zcc查出事假，赋值当天旷工为0.5 确认 事假小时数/7.5*0.5
            List<String> saturdayList = new ArrayList<String>();
            List<String> saturdayList1 = new ArrayList<String>();//用于接收当前存在打卡记录的集合
            String saturdayForWorkSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and ATTENDANCESTATUS=2";
            RecordSet rs7 = new RecordSet();
            rs7.execute(saturdayForWorkSql);
            while (rs7.next()) {
                String curdate = rs7.getString(1);
                saturdayList.add(curdate);
            }
            String sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname,hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType,hre.id  FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid=hde.id WHERE hre.accounttype !=1 and hre.id= "+userId+" ";
            sql+="AND CASE WHEN hre.startdate is NULL THEN '"+checkMaxDate+"' ELSE hre.startdate END <= '"+checkMaxDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+checkMinDate+"' ELSE hre.enddate END >= '"+checkMinDate+"' and hre.subcompanyid1=761  ORDER BY hde.id,hsc.signDate ASC";

            //b.writeLog("当前语句sql："+sql);
            //定义集合，把数据进行封装
            Map<String,Map<String,List<String>>> areaResult = getAreaResult(sql);
            //b.writeLog("areaResult："+areaResult);
            Map<String,Integer> statusMap=getDayStatus(month);
            //判断获取的数据是否为空
            if(areaResult!=null && areaResult.size()>0){
                //获取结果集所有键的集合，用keySet()方法实现
                Set<String> keySet = areaResult.keySet();
                //遍历键的集合，获取到每一个键。用增强for实现

                for (String key : keySet) {

                    String subcompanyname = key.split(",")[0]; //公司名
                    String departmentname = key.split(",")[1]; //部门名
                    String workCode = key.split(",")[2];       //工号
                    String lastname = key.split(",")[3];       //用户名
                    String id = key.split(",")[4];             //用户id
                    out.println("<tr id='trr3'>");
                    out.println("<td align='center'>"+subcompanyname+"</td>");
                    out.println("<td align='center'>"+departmentname+"</td>");
                    out.println("<td align='center'>"+workCode+"</td>");
                    out.println("<td align='center'>"+lastname+"</td>");
                    out.println("<td align='center'>"+month3+"</td>");

                    //根据键去找值，用get(Object key)方法实现
                    Map<String, List<String>> value = areaResult.get(key);
                    //单独处理总经理考勤报表 20201021 zcc
                    if("5872".equals(id)){
                        //遍历本月整天出勤的集合attendancestatus=0
                        for(String day1:curdateList){
                            //如果当天不包含请假数据，则将标准数据注入 含有请假数据，则根据请假时间段进行更新数据
                            if(value.keySet().contains(day1)){
                                List<String> list = value.get(day1);
                                list.addAll(getStandardSignTime());
                                value.put(day1,list);
                            }else{
                                value.put(day1,getStandardSignTime());
                            }
                        }
                        //遍历本月半天出勤的集合attendancestatus=2
                        for(String day2:saturdayList){
                            //如果当天不包含请假数据，则将标准数据注入 含有请假数据，则根据请假时间段进行更新数据
                            if(value.keySet().contains(day2)){
                                List<String> list = value.get(day2);
                                list.add("08:30:00:1");
                                list.add("11:45:00:2");
                                value.put(day2,list);
                            }else{
                                List<String> list = new LinkedList<String>();
                                list.add("08:30:00:1");
                                list.add("11:45:00:2");
                                value.put(day2,list);
                            }
                        }
                        //查询出当月请假日期，用集合接收
                        List<String> curLeaveCondition = getCurLeaveCondition(month,id);
                        if(curLeaveCondition.size()>0){
                            for(int i= 0;i<curLeaveCondition.size();i++){
                                String leaveDate=curLeaveCondition.get(i).split(",")[0];//请假日期
                                String leaveStartTime =curLeaveCondition.get(i).split(",")[1];//请假开始时间
                                String leaveEndTime =curLeaveCondition.get(i).split(",")[2];//请假结束时间
                                List<String> list = value.get(leaveDate);
                                if(curdateList.contains(leaveDate)){
                                    //当天为工作日 获取当天的集合 上午半天 全天 下午半天
                                    if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=705&&getTimeMin(leaveEndTime)<=780){
                                        list.remove("08:30:00:1");
                                        list.remove("11:45:00:2");
                                    }else if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=1035){
                                        list.remove("08:30:00:1");
                                        list.remove("11:45:00:2");
                                        list.remove("13:00:00:1");
                                        list.remove("17:15:00:2");
                                    }else if(getTimeMin(leaveStartTime)>=705&&getTimeMin(leaveStartTime)<=780&&getTimeMin(leaveEndTime)>=1035){
                                        list.remove("13:00:00:1");
                                        list.remove("17:15:00:2");
                                    }
                                }else if(saturdayList.contains(leaveDate)){
                                    //当天为单休周六上午
                                    if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=705){
                                        list.remove("08:30:00:1");
                                        list.remove("11:45:00:2");
                                    }
                                }else{
                                    //当天为非工作日
                                }
                            }
                        }
                    }
                    //调用方法，改变出差时的打卡时间
                    businessCommonController.changeBusinessTripTime(value,checkMinDate,checkMaxDate,id,likeDate,"1","2");

                    //调用方法，改变异常考勤时的打卡时间
                    abnormalCommonController.changeAbnormalSignTime(value,id,likeDate);

                    //调用方法，改变请假(调休)的打卡时间
                   //changeLeaveTime(value, id,likeDate,8,"3","4");
                    leaveCommonController.changeLeaveTime(value, id,likeDate,8,"3","4");
                    b.writeLog("==========qwer"+value);
                    //调用方法，改变请假(年假)的打卡时间
                    //changeLeaveTime(value, id,likeDate,0,"3","4");
                    leaveCommonController.changeLeaveTime(value, id,likeDate,0,"3","4");
                    //调用方法，改变请假(事假)的打卡时间
                    //changeLeaveTime(value, id,likeDate,9,"5","6");
                    leaveCommonController.changeLeaveTime(value, id,likeDate,9,"5","6");

                    //判断value集合是否为空
                    if(value.size()>0){
                        //获取结果集所有键的集合，用keySet()方法实现
                        Set<String> valueSet = value.keySet();
                        //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
                        TreeSet<String> ts_set = getDateTreeSet();
                        ts_set.addAll(valueSet);
                        //定义一个初始值
                        int day = 0;
                        //遍历键的集合，获取到每一个键。用增强for实现
                        for (String curdate : ts_set) {
                            if(Integer.parseInt(curdate.split("-")[1])==Integer.parseInt(likeDate.split("-")[1])){
                                String day1 = curdate.split("-")[2];
                                int day2 = Integer.parseInt(day1);
                                //根据键去找值，用get(Object key)方法实现
                                List<String> timeList = value.get(curdate);
                                Collections.sort(timeList);
                                //遍历得到第一个天数，减去初始值，然后循环这个天数减去初始值得到结果的数量的td标签
                                for(int j = 1;j < day2-day;j++){
                                    out.println("<td>");
                                    out.println("</td>");
                                }
                                //把遍历得到的第一个天数赋值给初始值
                                day=day2;
                                //out.println("<td>");

                                List<String> finalTimeList =finalTimeListController.getFinalTimeList(timeList);

                                //对哺乳假数据进行处理
                                List<String> newFinalTimeList = reviseFinalTimeList(finalTimeList, curdate, id);
                                b.writeLog("当前日期:>>>" + curdate + "对应打卡记录:>>>" + newFinalTimeList);
                                double count = 0.0;
                                if(curdateList.contains(curdate)){
                                    ////b.writeLog("--------------------------------------2020.06.28---");
                                    List<String> morningList1=new LinkedList<String>();
                                    List<String> afternoonList1=new LinkedList<String>();
                                    for (String time5:newFinalTimeList){
                                        int time5ForMin=getTimeMin(time5);
                                        if(time5ForMin<720){
                                            morningList1.add(time5);
                                            Collections.sort(morningList1);
                                        }else{
                                            afternoonList1.add(time5);
                                            Collections.sort(afternoonList1);
                                        }
                                    }
                                    for(String time6:morningList1){
                                        if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                                            morningList1.remove(time6);
                                            break;
                                        }
                                    }
                                    //计算上午打卡情况
                                    count +=(morningList1.size()<=1)?0.5:0;
                                    List<String> afternoonList2=new LinkedList<String>();
                                    for(String time6:afternoonList1){
                                        if(time6.endsWith("1")&&(time6.compareTo("17:15:00:1")>0)){
                                            afternoonList1.remove(time6);
                                            break;
                                        }
                                    }
                                    for(String clockOut:afternoonList1){
                                        if(clockOut.endsWith("2")){
                                            afternoonList2.add(clockOut);
                                        }
                                    }
                                    int afternoonList1Size=afternoonList1.size();
                                    afternoonList1Size=(afternoonList2.size()>=2)?(afternoonList1Size-afternoonList2.size()+1):afternoonList1Size;
                                    //计算下午打卡情况
                                    count +=(afternoonList1Size<=1)?0.5:0;
                                    ////b.writeLog("当天日期:"+curdate+";当天下午旷工:"+count);
                                    curdateList1.add(curdate);
                                    if(count !=0.0){
                                        abnormalList.add(curdate);
                                    }
                                }else if(saturdayList.contains(curdate)){
                                    ////b.writeLog("--------------------------------------2020.06.28---");
                                    List<String> morningList1=new LinkedList<String>();
                                    for (String time5:newFinalTimeList){
                                        int time5ForMin=getTimeMin(time5);
                                        if(time5ForMin<720){
                                            morningList1.add(time5);
                                            Collections.sort(morningList1);
                                        }
                                    }
                                    for(String time6:morningList1){
                                        if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                                            morningList1.remove(time6);
                                            break;
                                        }
                                    }
                                    ////b.writeLog("当天日期:"+curdate+"<---->当天上午打卡情况:"+morningList1+"<---->当天打卡大小："+morningList1.size());
                                    //计算周六打卡情况
                                    count +=(morningList1.size()<=1)?0.5:0;
                                    ////b.writeLog("当天日期:"+curdate+";当天旷工:"+count);
                                    saturdayList1.add(curdate);
                                }
                                if(count !=0.0 ){
                                    abnormalList.add(curdate);
                                }
                                if(abnormalList.contains(curdate)){
                                    out.println("<td id='td1'>");
                                }else{
                                    out.println("<td>");
                                }
                                b.writeLog("===asd==="+newFinalTimeList);
                                if(newFinalTimeList.size()>0){
                                    for(String time6:newFinalTimeList){
                                        int signtimeForMin=Integer.parseInt(time6.split(":")[0])*60+Integer.parseInt(time6.split(":")[1]);
                                        int attendanceStatus=statusMap.get(curdate);//获取当天的出勤状态
                                        if(attendanceStatus==0){
                                            if(time6.endsWith("1")||time6.endsWith("2")){
                                                if(time6.endsWith("1")&&Integer.parseInt(time6.substring(0,2))<12){
                                                    if(signtimeForMin>8*60+30){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{
                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }else if(time6.endsWith("1")&&Integer.parseInt(time6.substring(0,2))>=12){
                                                    if(signtimeForMin>13*60+15){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{

                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }else if(time6.endsWith("2")&&Integer.parseInt(time6.substring(0,2))<12){
                                                    if(signtimeForMin<11*60+45){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{
                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }else if(time6.endsWith("2")&&Integer.parseInt(time6.substring(0,2))>=12){
                                                    if(signtimeForMin<17*60+15){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{
                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }
                                            }else if(time6.endsWith("3")||time6.endsWith("4")){
                                                out.println("<font color='green'>"+time6.substring(0,5)+" </font><br> ");
                                            }else if(time6.endsWith("5")||time6.endsWith("6")){
                                                out.println("<font color='blue'>"+time6.substring(0,5)+" </font><br> ");
                                            }else{
                                                out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                            }
                                        }else if(attendanceStatus==2){
                                            if(time6.endsWith("1")||time6.endsWith("2")){
                                                if(time6.endsWith("1")&&Integer.parseInt(time6.substring(0,2))<12){
                                                    if(signtimeForMin>8*60+30){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{
                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }else if(time6.endsWith("2")&&Integer.parseInt(time6.substring(0,2))<12){
                                                    if(signtimeForMin<11*60+45){
                                                        out.println("<font color='red'>"+time6.substring(0,5)+" </font><br> ");
                                                    }else{
                                                        out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                    }
                                                }else{
                                                    out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                                }
                                            }else if(time6.endsWith("3")||time6.endsWith("4")){
                                                out.println("<font color='green'>"+time6.substring(0,5)+" </font><br> ");
                                            }else if(time6.endsWith("5")||time6.endsWith("6")){
                                                out.println("<font color='blue'>"+time6.substring(0,5)+" </font><br> ");
                                            }else{
                                                out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                            }
                                        }else if(attendanceStatus==1){
                                            out.println("<font>"+time6.substring(0,5)+" </font><br> ");
                                        }
                                        b.writeLog("===asd==="+time6);
                                    }
                                    out.println("</td>");
                                }
                            }
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
                out.println("<tr><font color='blue' align='left'>备注:红色表示迟到、早退;绿色表示调休、年休假;蓝色表示事假；灰色框表示当天打卡数据缺失</font></tr>");
            }else{
                //为空则输出无查询结果
                out.println("<tr>");
                out.println("<td colspan='"+roll+"' style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center'>无查询结果，请确认查询报表条件</td>");
                out.println("</tr>");
            }
        %>
        <%!
            public static Long getTimeMillis(Calendar c){
                c.set(Calendar.DAY_OF_MONTH, c.get(Calendar.DAY_OF_MONTH) + 1);
                return c.getTimeInMillis();
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


        <!-- 对yyyy-MM-dd格式日期进行排序getDateTreeSet() -->
        <%!
            public static TreeSet<String> getDateTreeSet() {
                return new TreeSet<String>(new Comparator<String>() {
                    public int compare(String s1, String s2) {
                        String[] split = s1.split("-");
                        int i1 = Integer.parseInt(split[2]);
                        String[] split2 = s2.split("-");
                        int i2 = Integer.parseInt(split2[2]);
                        return i1 - i2;
                    }
                });
            }
        %>

        <!-- 获取从数据库查询到的数据进行封装getAreaResult(String sql) -->
        <%!
            public static Map<String, Map<String, List<String>>> getAreaResult(String sql) {
                RecordSet rs = new RecordSet();
                rs.execute(sql);
                //定义集合，把数据进行封装
                Map<String, Map<String, List<String>>> areaResult = new LinkedHashMap<String, Map<String, List<String>>>();
                while (rs.next()) {
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
                    //员工id
                    String id = Util.null2String(rs.getString("id"));
                    //法定节假日
                    String holiday = Util.null2String(rs.getString("holiday"));
                    if (!signTime.isEmpty() && !signType.isEmpty()) {
                        signTime = signTime + ":" + signType;
                    }
                    //定义集合的key值
                    String key = subcompanyname + "," + departmentname + "," + workCode + "," + lastname + "," + id+","+days+","+holiday;

                    //判断是否是同一个人
                    if (areaResult.containsKey(key)) {
                        //判断是否是同一天
                        if (areaResult.get(key).containsKey(signDate)) {
                            areaResult.get(key).get(signDate).add(signTime);
                        } else {
                            List<String> timeList1 = new ArrayList<String>();
                            timeList1.add(signTime);
                            areaResult.get(key).put(signDate, timeList1);
                        }
                    } else {
                        Map<String, List<String>> areaResult1 = new HashMap<String, List<String>>();
                        List<String> timeList2 = new ArrayList<String>();
                        if (!signTime.isEmpty() && !signDate.isEmpty()) {
                            timeList2.add(signTime);
                            areaResult1.put(signDate, timeList2);
                            areaResult.put(key, areaResult1);
                        } else {
                            areaResult.put(key, areaResult1);
                        }
                    }
                }
                return areaResult;
            }
        %>

        <!--获取半小时后的时间-->
        <%!
            public static String getHalfHour(String time) {
                int hour = Integer.parseInt(time.substring(0, 2));
                int minute = Integer.parseInt(time.substring(3, 5));
                String time1 = ((hour + 1) <= 9 ? ("0" + (hour + 1)) : (String.valueOf(hour + 1))) + ":" +
                        ((minute - 30 <= 9) ? ("0" + (minute - 30)) : (String.valueOf(minute - 30))) + time.substring(5);
                String time2 = ((hour) <= 9 ? ("0" + hour) : (String.valueOf(hour))) + ":" +
                        ((minute + 30 <= 9) ? ("0" + (minute + 30)) : (String.valueOf(minute + 30))) + time.substring(5);
                return minute >= 30 ? time1 : time2;
            }
        %>
        <!--获取半小时前的时间-->
        <%!
            public static String getBeforeHalfHour(String curTime) {
                int hour1 = Integer.parseInt(curTime.substring(0, 2));
                int minute1 = Integer.parseInt(curTime.substring(3, 5));
                String time3 = ((hour1) <= 9 ? ("0" + hour1) : (String.valueOf(hour1))) + ":" +
                        ((minute1 - 30 <= 9) ? ("0" + (minute1 - 30)) : (String.valueOf(minute1 - 30))) + curTime.substring(5);
                String time4 = ((hour1 - 1) <= 9 ? ("0" + (hour1 - 1)) : (String.valueOf(hour1 - 1))) + ":" +
                        ((minute1 + 30 <= 9) ? ("0" + (minute1 + 30)) : (String.valueOf(minute1 + 30))) + curTime.substring(5);
                return minute1 >= 30 ? time3 : time4;
            }
        %>
        <!--对哺乳假数据进行处理-->
        <%!
            private static List<String> reviseFinalTimeList(List<String> finalTimeList, String curdate, String id) {
                List<String> newFinalTimeList = new ArrayList<String>();//定义结合接收修正后的数据
                //对哺乳假数据进行处理
                String getLactationSql = "SELECT start_date,end_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from uf_lactation where userid='" + id + "' ";
                RecordSet getLactationRs = new RecordSet();
                getLactationRs.execute(getLactationSql);
                ////b.writeLog("哺乳假sql语句:"+getLactationSql);
                while (getLactationRs.next()) {
                    String startDate = Util.null2String(getLactationRs.getString("start_date"));//哺乳假的开始日期
                    String endDate = Util.null2String(getLactationRs.getString("end_date"));//哺乳假的结束日期
                    String morningSignIn = Util.null2String(getLactationRs.getString("morning_sign_in"));//上午签到
                    String morningSignBack = Util.null2String(getLactationRs.getString("morning_sign_back"));//上午签退
                    String afternoonSignIn = Util.null2String(getLactationRs.getString("afternoon_sign_in"));//下午签到
                    String afternoonSignBack = Util.null2String(getLactationRs.getString("afternoon_sign_back"));//下午签退
                    //请一次假 1个小时
                    boolean result1 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到1小时
                    boolean result2 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退1小时
                    boolean result3 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//下午签到1小时
                    boolean result4 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签退1小时
                    //请两次假 两个半小时
                    boolean result5 = (("1").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 上午签退
                    boolean result6 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 下午签到
                    boolean result7 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签到 下午签退
                    boolean result8 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退 下午签到
                    boolean result9 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签退 下午签退
                    boolean result10 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签到 下午签退
                    ////b.writeLog("当前日期与开始日期比较结果:"+startDate.compareTo(curdate)+";结束日期与当前日期比较结果:"+endDate.compareTo(curdate));
                    //比较打卡日期 在哺乳假开始日期与结束日期之间
                    if (startDate.compareTo(curdate) <= 0 && endDate.compareTo(curdate) >= 0) {
                        ////b.writeLog("开始修正符合条件的数据,当前日期为:"+curdate+",哺乳假开始日期:"+startDate+",哺乳假开始日期:"+endDate);
                        for (String time : finalTimeList) {
                            //上午签到晚1小时
                            if (result1) {
                                //取出上午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = (Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : ((Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2);
                                    time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                                }
                            }
                            //上午签退早1小时
                            if (result2) {
                                //取出上午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
                                    time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                                }
                            }
                            //下午签到晚1小时
                            if (result3) {
                                //取出下午签退时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = ((Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1))) + time.substring(2);
                                    time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                                }
                            }
                            //下午签退早1小时
                            if (result4) {
                                //取出下午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + (Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
                                    time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                                }
                            }
                            //上午签到 上午签退 各半小时
                            if (result5) {
                                //取出上午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                                }
                                //取出上午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getHalfHour(time);//算出后小时后的数据
                                    time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                                }
                            }
                            //上午签到 下午签到 各半小时
                            if (result6) {

                                //取出上午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                                }
                                //取出下午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                                }
                                ////b.writeLog("满足该条件:当前修正后打卡时间为:"+time);
                            }
                            //上午签到 下午签退 各半小时
                            if (result7) {
                                //取出上午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果大于08：30，则取08：30
                                }
                                //取出下午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getHalfHour(time);//算出后小时后的数据
                                    time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果小于17:15，则取17:15
                                }
                            }
                            //上午签退 下午签到 各半小时
                            if (result8) {
                                //取出上午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getHalfHour(time);//算出半小时后的数据
                                    time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45

                                }
                                //取出下午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                                }
                            }
                            //上午签退 下午签退 各半小时
                            if (result9) {
                                //取出上午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                    time = getHalfHour(time);
                                    time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                                }
                                //取出下午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getHalfHour(time);//算出半小时后的数据
                                    time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                                }
                            }
                            //下午签到 下午签退 各半小时
                            if (result10) {
                                //取出下午签到时间
                                if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getBeforeHalfHour(time);//算出半小时前的数据
                                    time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                                }
                                //取出下午签退时间
                                if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                    time = getHalfHour(time);//算出半小时后的数据
                                    time = time.compareTo("17:15:00:2") <= 0 ? time : "17:15:00:2";//修正后的时间如果大于17:15，则取17:15
                                }
                            }
                            newFinalTimeList.add(time);//将数据重新放入新的集合中
                        }
                    }
                }
                if(newFinalTimeList.size()==0){
                    newFinalTimeList=finalTimeList;
                }
                return newFinalTimeList;
            }
        %>
        <!--查询单结果为string对应的名称-->
        <%!
            public static String getName(String sql) {
                RecordSet recordSet = new RecordSet();
                recordSet.execute(sql);
                recordSet.next();
                return recordSet.getString(1);
            }
        %>
        <!--查询单结果为int对应的名称-->
        <%!
            public static int getId(String getCompanyIdSql){
                RecordSet recordSet = new RecordSet();
                recordSet.execute(getCompanyIdSql);
                recordSet.next();
                return recordSet.getInt(1);
            }
        %>
        <%!
            /**
             * 将字符串类型的时间转换成分钟数
             * @param curTime
             * @return int
             */
            public static int getTimeMin(String curTime) {
                return Integer.parseInt(curTime.split(":")[0])*60+Integer.parseInt(curTime.split(":")[1]);
            }
        %>
        <!--查询出开始日期到结束日期包含的日期-->
        <%!
            public static ArrayList<String> findDates(String stime, String etime){
                ArrayList<String> allDate = new ArrayList<String>();
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                Date dBegin = null;
                try {
                    dBegin = sdf.parse(stime);
                } catch (ParseException e) {
                    e.printStackTrace();
                }
                Date dEnd = null;
                try {
                    dEnd = sdf.parse(etime);
                } catch (ParseException e) {
                    e.printStackTrace();
                }
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
        <%!
            /**
             * 计算两个时间相差的小时数(保留两位小数)
             * @param startTime
             * @param endTime
             * @return String
             */
            private static String getDifferenceHours(String startTime, String endTime){
                DecimalFormat df=new DecimalFormat("0.00");
                int firstSignForMin1=getTimeMin(startTime);//第一次打卡对应的分钟数
                int secondSignForMin1=getTimeMin(endTime);//第二次打卡对应的分钟数
                return df.format((float)(secondSignForMin1-firstSignForMin1)/60);
            }
        %>
        <%!
            private static Map<String,Integer> getDayStatus(String month){
                Map<String,Integer> map=new TreeMap<String, Integer>();
                String sql="select curdate,ATTENDANCESTATUS from uf_attendance where curdate like '%" + month + "%' ";
                RecordSet recordSet=new RecordSet();
                recordSet.execute(sql);
                while(recordSet.next()){
                    String curdate=recordSet.getString("curdate");
                    int attendanceStatus=recordSet.getInt("ATTENDANCESTATUS");
                    map.put(curdate,attendanceStatus);
                }
                return map;
            }
        %>
        <%!
            /**
             * 获取标准打卡时间
             * @return List<Integer>
             */
            private static List<String> getStandardSignTime() {
                List<String> standardList = new ArrayList<String>();
                standardList.add(0, "08:30:00:1");
                standardList.add(1, "11:45:00:2");
                standardList.add(2, "13:00:00:1");
                standardList.add(3, "17:15:00:2");
                return standardList;
            }
        %>
        <%!
            /**
             * 获取当天的请假日期和请假开始时间和请假结束时间
             * @param curdate
             * @param id
             * @return List<String>
             */
            private static List<String> getCurLeaveCondition(String curdate, String id) {
                String getLeaveSql = "select * from uf_AskForLeave where userid='" + id + "'  and type in (0,8,9) and start_date>='" + curdate + "' and end_date<= '" + curdate + "'";
                RecordSet getLeaveRs = new RecordSet();
                //b.writeLog("当月请假sql语句为:"+getLeaveSql);
                getLeaveRs.execute(getLeaveSql);
                String leaveRecord = "";
                List<String> leaveRecordList = new ArrayList<String>();
                //获取当天请假日期 请假开始时间 请假结束时间
                while (getLeaveRs.next()) {
                    String startDate = Util.null2String(getLeaveRs.getString("start_date"));
                    //调休(年假)请假结束日期
                    String endDate = Util.null2String(getLeaveRs.getString("end_date"));
                    //调休(年假)请假开始时间
                    String startTime = Util.null2String(getLeaveRs.getString("start_time"));
                    //调休(年假)请假结束时间
                    String endTime = Util.null2String(getLeaveRs.getString("end_time"));
                    //获取请假当天出勤状态 0全天出勤 1非出勤 2出勤半天
                    String status = getAttendanceStatus(curdate);
                    if (startDate.equals(endDate)) {
                        //如果请假天数为1天
                        if (status.equals("0")) {
                            //请假开始时间小于08:30则默认为08：30；请假结束时间大于17：15则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                            startTime = startTime.compareTo("08:30") <= 0 ? "08:30" : startTime;
                            endTime = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                            leaveRecord = curdate + "," + startTime + "," + endTime;
                        } else if (status.equals("2")) {
                            //请假开始时间小于08:30则默认为08：30；请假结束时间大于11：45则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                            startTime = startTime.compareTo("08:30") <= 0 ? "08:30" : startTime;
                            endTime = endTime.compareTo("11:45") >= 0 ? "11:45" : endTime;
                            leaveRecord = curdate + "," + startTime + "," + endTime;
                        }
                    } else {
                        //如果请假天数大于1天
                        if (curdate.equals(startDate)) {
                            //当天为开始日期
                            if (status.equals("0")) {
                                //请假开始时间大于17:15则默认为17:15；请假结束时间默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = startTime.compareTo("17:15") >= 0 ? "17:15" : startTime;
                                endTime = "17:15";
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            } else if (status.equals("2")) {
                                //请假开始时间大于11:45则默认为11:45；请假结束时间默认为11:45 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = startTime.compareTo("11:45") >= 0 ? "11:45" : startTime;
                                endTime = "11:45";
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            }
                        } else if (curdate.equals(endDate)) {
                            //当天为结束日期
                            if (status.equals("0")) {
                                //请假开始时间默认为08:30；请假结束时间大于17：15则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = "08:30";
                                endTime = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            } else if (status.equals("2")) {
                                //请假开始时间默认为08:30；请假结束时间大于11：45则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = "08:30";
                                endTime = endTime.compareTo("11:45") >= 0 ? "11:45" : endTime;
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            }
                        } else {
                            //当天不为开始日期和结束日期
                            if (status.equals("0")) {
                                //请假开始时间默认为08:30；请假结束时间则默认为17：15 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = "08:30";
                                endTime = "17:15";
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            } else if (status.equals("2")) {
                                //请假开始时间默认为08:30；请假结束时间则默认为11：45 请假记录格式为 请假日期，开始时间，结束时间
                                startTime = "08:30";
                                endTime = "11:45";
                                leaveRecord = curdate + "," + startTime + "," + endTime;
                            }
                        }
                    }
                    //将请假记录统一放入到集合中
                    leaveRecordList.add(leaveRecord);
                }
                return leaveRecordList;
            }
        %>
        <%!
            /**
             * 获取当天的出勤状态 0 出勤满 1 非出勤 2出勤半天
             * @param curdate
             * @return String
             */
            private static String getAttendanceStatus(String curdate) {
                String getAttendanceStatusSql = "select attendanceStatus from uf_attendance where curdate like '%" + curdate + "%'";
                return getName(getAttendanceStatusSql);
            }
        %>
    </table>
</div>
</body>