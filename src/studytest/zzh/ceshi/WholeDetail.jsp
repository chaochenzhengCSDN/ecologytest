<!-- 门店考勤月报表 -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="weaver.conn.RecordSet" %>
<%@page import="java.text.DecimalFormat" %>
<%@page import="java.text.ParseException" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
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
        #td1 {
            background-color:#ccc;
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
//                    if("5872".equals(id)){
//                        //遍历本月整天出勤的集合attendancestatus=0
//                        for(String day1:curdateList){
//                            //如果当天不包含请假数据，则将标准数据注入 含有请假数据，则根据请假时间段进行更新数据
//                            value.put(day1,getStandardSignTime());
//                        }
//                        //遍历本月半天出勤的集合attendancestatus=2
//                        for(String day2:saturdayList){
//                            //如果当天不包含请假数据，则将标准数据注入 含有请假数据，则根据请假时间段进行更新数据
//                            value.put(day2,getStandardSignTime());
//                        }
//                        //查询出当月请假日期，用集合接收
//                        List<String> curLeaveCondition = getCurLeaveCondition(month,id);
//                        if(curLeaveCondition.size()>0){
//                            for(int i= 0;i<curLeaveCondition.size();i++){
//                                String leaveDate=curLeaveCondition.get(i).split(",")[0];//请假日期
//                                String leaveStartTime =curLeaveCondition.get(i).split(",")[1];//请假开始时间
//                                String leaveEndTime =curLeaveCondition.get(i).split(",")[2];//请假结束时间
//                                List<String> list = value.get(leaveDate);
//                                if(curdateList.contains(leaveDate)){
//                                    //当天为工作日 获取当天的集合 上午半天 全天 下午半天
//                                    if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=705&&getTimeMin(leaveEndTime)<=780){
//                                        list.remove("08:30:00:1");
//                                        list.remove("11:45:00:2");
//                                    }else if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=1035){
//                                        list.remove("08:30:00:1");
//                                        list.remove("11:45:00:2");
//                                        list.remove("13:00:00:1");
//                                        list.remove("17:15:00:2");
//                                    }else if(getTimeMin(leaveStartTime)>=705&&getTimeMin(leaveStartTime)<=780&&getTimeMin(leaveEndTime)>=1035){
//                                        list.remove("13:00:00:1");
//                                        list.remove("17:15:00:2");
//                                    }
//                                }else if(saturdayList.contains(leaveDate)){
//                                    //当天为单休周六上午
//                                    if(getTimeMin(leaveStartTime)<=510&&getTimeMin(leaveEndTime)>=705){
//                                        list.remove("08:30:00:1");
//                                        list.remove("11:45:00:2");
//                                    }
//                                }else{
//                                    //当天为非工作日
//                                }
//                            }
//                        }
//                    }
                    //调用方法，改变出差时的打卡时间
                    changeBusinessTripTime(value,checkMinDate,checkMaxDate,id,likeDate,"1","2");

                    //调用方法，改变异常考勤时的打卡时间
                    changeAbnormalSignTime(value,id,likeDate);

                    //调用方法，改变请假(调休)的打卡时间
                    changeLeaveTime(value, id,likeDate,8,"3","4");

                    //调用方法，改变请假(年假)的打卡时间
                    changeLeaveTime(value, id,likeDate,0,"3","4");

                    //调用方法，改变请假(事假)的打卡时间
                    changeLeaveTime(value, id,likeDate,9,"5","6");
                    
                    //调用方法，改变请假(婚假)的打卡时间
                    changeLeaveTime(value,  id,likeDate,1,"5","6");
                    //调用方法，改变请假(产假)的打卡时间
                    changeLeaveTime(value,  id,likeDate,2,"5","6");
                    //b.writeLog("value："+value);
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

                                //调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
                                List<String> morningTimeList = getMorningTimeList(timeList);

                                //调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
                                List<String> afternoonTimeList = getAfternoonTimeList(timeList);

                                //调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
                                List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);

                                //调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
                                List<String> finalTimeList = getFinalTimeList(morningTimeList, afternoonTimeList, confirmTimeList);
                                ////b.writeLog("当前日期:>>>" + curdate + "对应打卡记录:>>>" + finalTimeList);
                                //对哺乳假数据进行处理
                                List<String> newFinalTimeList = reviseFinalTimeList(finalTimeList, curdate, id);

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
                                }
                                out.println("</td>");
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

        <!-- 对HH:mm:ss格式时间进行排序getTimeTreeSet() -->
        <%!
            public static TreeSet<String> getTimeTreeSet() {
                //创建TreeSet集合对象
                return new TreeSet<String>(new Comparator<String>() {
                    public int compare(String s1, String s2) {
                        String[] split1 = s1.split(":");
                        int s11 = Integer.parseInt(split1[0]);
                        int s12 = Integer.parseInt(split1[1]);
                        int s13 = Integer.parseInt(split1[2]);
                        String[] split2 = s2.split(":");
                        int s21 = Integer.parseInt(split2[0]);
                        int s22 = Integer.parseInt(split2[1]);
                        int s23 = Integer.parseInt(split2[2]);

                        int num = s11 - s21;
                        int num2 = num == 0 ? s12 - s22 : num;
                        return num2 == 0 ? s13 - s23 : num2;
                    }
                });
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

        <!-- 获取上午时段的打卡时间 -->
        <%!
            public static List<String> getMorningTimeList(List<String> list) {
                //定义第一个集合，添加上午时段的打卡时间
                List<String> morningTimeList = new ArrayList<String>();
                //定义第二个集合，添加上午时段的上班卡时间
                List<String> morningUpTimeList = new ArrayList<String>();
                //定义第三个集合，添加上午时段的下班卡时间
                List<String> morningDownTimeList = new ArrayList<String>();
                for (String time : list) {
                    String[] split1 = time.split(":");
                    int hour = Integer.parseInt(split1[0]);
                    int minute = Integer.parseInt(split1[1]);
                    int seconds = Integer.parseInt(split1[2]);
                    int typeInt = Integer.parseInt(split1[3]);
                    if (0 <= hour && hour < 12 && 0 <= minute && minute < 60 && 0 <= seconds && seconds < 60) {
                        if (typeInt == 1) {
                            morningUpTimeList.add(time);
                        } else if (typeInt == 2) {
                            morningDownTimeList.add(time);
                        }
                        //2020.06.23 zcc
                        else if (typeInt == 3 || typeInt == 4 || typeInt == 5 || typeInt == 6 || typeInt == 7 || typeInt == 8) {
                            morningTimeList.add(time);
                        }
                    }
                }
                if (morningUpTimeList.size() > 0) {
                    //获取上午上班卡最早的一个打卡时间
                    String time = morningUpTimeList.get(0);
                    morningTimeList.add(time);
                }
                if (morningDownTimeList.size() > 0) {
                    //获取上午下班卡最晚的一个打卡时间
                    String time = morningDownTimeList.get((morningDownTimeList.size()) - 1);
                    morningTimeList.add(time);
                }
                Collections.sort(morningTimeList);
                ////b.writeLog("当天上午打卡记录："+morningTimeList);
                return morningTimeList;
            }
        %>

        <!-- 获取下午时段的打卡时间 -->
        <%!
            public static List<String> getAfternoonTimeList(List<String> list) {
                BaseBean b =new BaseBean ();
                //定义第一个集合，添加下午时段的打卡时间
                List<String> afternoonTimeList = new ArrayList<String>();
                //定义第二个集合，添加下午时段的上班卡时间
                List<String> afternoonUpTimeList = new ArrayList<String>();
                //定义第三个集合，添加下午时段的下班卡时间
                List<String> afternoonDownTimeList = new ArrayList<String>();
                for (String time : list) {
                    String[] split1 = time.split(":");
                    int hour = Integer.parseInt(split1[0]);
                    int minute = Integer.parseInt(split1[1]);
                    int seconds = Integer.parseInt(split1[2]);
                    int typeInt = Integer.parseInt(split1[3]);
                    if (12 <= hour && hour < 24 && 0 <= minute && minute < 60 && 0 <= seconds && seconds < 60) {
                        if (typeInt == 1) {
                            afternoonUpTimeList.add(time);
                        } else if (typeInt == 2) {
                            afternoonDownTimeList.add(time);
                        }
                        //2020.06.23 zcc
                        else if (typeInt == 3 || typeInt == 4 || typeInt == 5 || typeInt == 6 || typeInt == 7 || typeInt == 8) {
                            afternoonTimeList.add(time);
                        }
                    }
                    
                }
                if (afternoonUpTimeList.size() > 0) {
                    //获取下午上班卡最早的一个打卡时间
                    String time = afternoonUpTimeList.get(0);
                    afternoonTimeList.add(time);
                }
                if (afternoonDownTimeList.size() > 0) {
                    //遍历下午下班卡
                    afternoonTimeList.addAll(afternoonDownTimeList);
                }
                Collections.sort(afternoonTimeList);
                return afternoonTimeList;
            }
        %>

        <!-- 获取下午17:15时段之后的打卡时间 -->
        <%!
            public static List<String> getConfirmTimeList(List<String> afternoonTimeList) {
                List<String> confirmTimeList = new ArrayList<String>();
                for (int y = 0; y < afternoonTimeList.size(); y++) {
                    String time = afternoonTimeList.get(y);
                    String[] split1 = time.split(":");
                    int hour = Integer.parseInt(split1[0]);
                    int minute = Integer.parseInt(split1[1]);
                    int seconds = Integer.parseInt(split1[2]);
                    int typeInt = Integer.parseInt(split1[3]);
                    if ((y == 0 && typeInt == 1) || (y == 0 && afternoonTimeList.size() == 1)) {

                    } else {
                        if ((hour > 17) || (hour == 17 && minute >= 15 && seconds < 60 && seconds >= 0)) {
                            confirmTimeList.add(time);
                        }
                    }
                }
                ////b.writeLog("当天打卡记录:"+confirmTimeList);
                return confirmTimeList;
            }
        %>

        <!-- 获取下午17:15时段之前的最终打卡时间 -->
        <%!
            public static List<String> getFinalAfternoonTimeList(List<String> afternoonTimeList) {
                BaseBean b=new BaseBean();
                //定义下午17:15时段之前的最终打卡时间的集合
                List<String> finalAfternoonTimeList = new ArrayList<String>();
                ////b.writeLog("afternoonTimeList:"+afternoonTimeList);
                List<String> afternoonTimeList1=new ArrayList<String>();
                List<String> leaveTimeList=new ArrayList<String>();
                for(String cTime:afternoonTimeList){
                    if(cTime.endsWith("1")||cTime.endsWith("2")){
                        afternoonTimeList1.add(cTime);
                    }else{
                        leaveTimeList.add(cTime);
                    }
                }
                ////b.writeLog("流程数据:"+leaveTimeList);
                for (int y = 0; y < afternoonTimeList1.size(); y++) {
                    String time = afternoonTimeList1.get(y);
                    String[] split1 = time.split(":");
                    int hour = Integer.parseInt(split1[0]);
                    int minute = Integer.parseInt(split1[1]);
                    int seconds = Integer.parseInt(split1[2]);
                    int typeInt = Integer.parseInt(split1[3]);
                    ////b.writeLog("afternoonTimeList:"+afternoonTimeList);
                    //1.2如果最后一次打卡在17:15:00之前，则取17:15:00之前的第一次打卡时间和最后一次打卡时间
                    if ((afternoonTimeList1.size()) > 1 && y == (afternoonTimeList1.size() - 1) && ((hour < 17) || (hour == 17 && minute < 15 && seconds < 60))) {
                        String time2 = afternoonTimeList1.get(y);
                        //b.writeLog("time2:"+time2);
                        finalAfternoonTimeList.add(time2);
                        //b.writeLog("finalAfternoonTimeList:"+finalAfternoonTimeList);
                        //1.3如果最后一次打卡在17:15:00之后则取下午时段的第一次打卡的时间和17:15:00之后打卡的时间
                    }
                    if ((y == 0 && typeInt == 1) || (y == 0 && afternoonTimeList1.size() == 1)) {
                        finalAfternoonTimeList.add(time);
                    }
                }
                for(String time2:leaveTimeList){
                    int time2ForMin=Integer.parseInt(time2.split(":")[0])*60+Integer.parseInt(time2.split(":")[1]);
                    if(time2ForMin<17*60+15){
                        finalAfternoonTimeList.add(time2);
                    }
                }
                Collections.sort(finalAfternoonTimeList);
                ////b.writeLog("17：15之前打卡时间为"+finalAfternoonTimeList);
                return finalAfternoonTimeList;
            }
        %>

        <!-- 获取下午17:15时段之后的最终打卡时间 -->
        <%!
            public static List<String> getFinalCofirmTimeList(List<String> confirmTimeList) {
                //定义下午17:15时段之后的最终打卡时间的集合
                List<String> finalCofirmTimeList = new ArrayList<String>();
                //1.如果17:15:00之后的时间集合里只有一个数据，那就直接展示
                if (confirmTimeList.size() == 1) {
                    String time = confirmTimeList.get(0);
                    finalCofirmTimeList.add(time);
                }

                //2.如果17:15:00之后的时间集合里有两个数据，判断这两个数据是否相差30分钟
                if (confirmTimeList.size() == 2) {
                    String time1 = confirmTimeList.get(0);
                    int secondsTime1 = getTime(time1);
                    String time2 = confirmTimeList.get(1);
                    int secondsTime2 = getTime(time2);
                    //2.1如果相差30分钟，则把这两个数据都展示出来
                    if (secondsTime2 - secondsTime1 >= 1800) {
                        finalCofirmTimeList.add(time1);
                        finalCofirmTimeList.add(time2);
                    } else {
                        //2.2如果不相差30分钟，则把最后一个数据展示出来
                        finalCofirmTimeList.add(time2);
                    }
                }

                List<String> countList = new ArrayList<String>();
                //3.如果17:15:00之后的时间集合里有超过两个数据的
                if (confirmTimeList.size() > 2) {
                    for (int z = 0; z < confirmTimeList.size(); z++) {
                        if (z == 0) {
                            String time = confirmTimeList.get(z);
                            countList.add(time);
                        } else {
                            if (finalCofirmTimeList.size() < 3) {
                                //3.1先取第一次打卡记录
                                String time1 = confirmTimeList.get(z - 1);
                                String time2 = confirmTimeList.get(z);
                                int secondsTime1 = getTime(time1);
                                int secondsTime2 = getTime(time2);
                                //3.2若存在30分钟后的打卡记录，则取第一次和30分钟后第一次的打卡记录
                                if (secondsTime2 - secondsTime1 >= 1800) {
                                    String time = confirmTimeList.get(0);
                                    finalCofirmTimeList.add(time);
                                    finalCofirmTimeList.add(time2);
                                    countList.add(time2);
                                    if (confirmTimeList.size() - (z + 1) > 0) {
                                        String time3 = confirmTimeList.get(confirmTimeList.size() - 1);
                                        finalCofirmTimeList.add(time3);
                                        countList.add(time3);
                                    }
                                } else {
                                    //3.3若不存在30分钟后的打卡记录，则取最后一次的打卡记录
                                    if (z == (confirmTimeList.size() - 1) && countList.size() == 1) {
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
            public static List<String> getFinalTimeList(List<String> morningTimeList, List<String> afternoonTimeList, List<String> confirmTimeList) {
                //遍历上午时段的打卡集合
                List<String> finalTimeList = new ArrayList<String>(morningTimeList);
                ////b.writeLog("上午数据："+finalTimeList);
                //遍历下午17:15时段之前的最终打卡集合
                List<String> finalAfternoonTimeList = getFinalAfternoonTimeList(afternoonTimeList);
                finalTimeList.addAll(finalAfternoonTimeList);
                ////b.writeLog("下午数据："+finalTimeList);
                //遍历下午时段17:15:00之后的时间集合
                List<String> finalCofirmTimeList = getFinalCofirmTimeList(confirmTimeList);
                finalTimeList.addAll(finalCofirmTimeList);
                ////b.writeLog("最终数据："+finalTimeList);
                return finalTimeList;
            }
        %>

        <!--改变出差时的打卡时间 -->
        <%!
            public static void changeBusinessTripTime(Map<String, List<String>> value, String checkMinDate, String checkMaxDate, String id, String month, String businessinFlag, String businessOutFlag) {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                BaseBean b = new BaseBean();
                String signInTime = "08:30:00:" + businessinFlag;
                String signBackTime = "11:45:00:" + businessOutFlag;
                String signInSecondTime = "13:00:00:" + businessinFlag;
                String signBackSecondTime = "17:15:00:" + businessOutFlag;
                List<String> businesstripTimeList1 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间 下午签到时间 下午签退时间
                businesstripTimeList1.add(signInTime);
                businesstripTimeList1.add(signBackTime);
                businesstripTimeList1.add(signInSecondTime);
                businesstripTimeList1.add(signBackSecondTime);
                String sql1 = "SELECT start_date,start_time,end_date,end_time from uf_BusinessTrip WHERE userid = " + id + " and (start_date like '%" + month + "%' or end_date like '%" + month + "%') ORDER BY start_date";
                RecordSet rs1 = new RecordSet();
                rs1.execute(sql1);
                //b.writeLog("出差记录查询sql:" + sql1);
                while (rs1.next()) {
                    List<String> dateList = new ArrayList<String>();
                    List<String> finalDateList = new ArrayList<String>();
                    //出差开始日期
                    String startDate = Util.null2String(rs1.getString("start_date"));
                    //出差结束日期
                    String endDate = Util.null2String(rs1.getString("end_date"));
                    //出差开始时间
                    String startTime = Util.null2String(rs1.getString("start_time"));
                    //出差结束时间
                    String endTime = Util.null2String(rs1.getString("end_time"));
                    //1.处理出差期间的考勤打卡时间(不包括出差开始日期和出差结束日期)
                    Calendar c1 = Calendar.getInstance();
                    try {
                        c1.setTime(sdf.parse(startDate));
                        long time = sdf.parse(endDate).getTime();
                        for (long d = c1.getTimeInMillis(); d <= time; d = getTimeMillis(c1)) {
                            dateList.add(sdf.format(d));
                        }
                        for (int i = 1; i < dateList.size() - 1; i++) {
                            String businesstripDate = dateList.get(i);
                            if (Integer.parseInt(businesstripDate.split("-")[1]) == Integer.parseInt(month.split("-")[1])) {
                                finalDateList.add(dateList.get(i));
                            }
                        }
                        for (String businesstripDate : finalDateList) {
                            //根据用户id和日期查询当天是否有业务考勤打卡记录
                            String attendanceSql1 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + businesstripDate + "'";
                            ////b.writeLog("出差开始日期是否有打卡记录:"+attendanceSql1);
                            int isAttendance1 = getId(attendanceSql1);
                            if (isAttendance1 >= 1) {
                                value.put(businesstripDate, businesstripTimeList1);
                            }
                        }
                        //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                        String attendanceSql2 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + startDate + "'";
                        String attendanceSql3 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + endDate + "'";
                        ////b.writeLog("出差开始日期是否有打卡记录:"+attendanceSql2);
                        int isAttendance2 = getId(attendanceSql2);
                        int isAttendance3 = getId(attendanceSql3);
                        //出差开始日期和出差结束日期不是同一天
                        if (!startDate.equals(endDate)) {
                            //2.处理出差开始当天的考勤打卡时间
                            //出差开始日期当天的打卡记录集合
                            //List<String> businesstripStartDate = value.get(startDate);
                            if (isAttendance2 >= 1) {
                                endTime = "17:15";
                                changeTodayTime(value, startTime, endTime, startDate, businessinFlag, businessOutFlag);
                            }
                            if (isAttendance3 >= 1) {
                                startTime = Integer.parseInt(startTime.split(":")[0]) * 60 + Integer.parseInt(startTime.split(":")[1]) >= 510 ? "08:30" : startTime;
                                changeTodayTime(value, startTime, endTime, endDate, businessinFlag, businessOutFlag);
                            }

                        } else {
                            //无业务考勤打卡记录
                            if(isAttendance2>=1){
                                //调用出差方法，处理当天的打卡时间
                                changeTodayTime(value, startTime, endTime, startDate, businessinFlag, businessOutFlag);
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            }
        %>


        <!--改变异常考勤时的打卡时间 -->
        <%!
            public static void changeAbnormalSignTime(Map<String, List<String>> value, String id, String month) {
                BaseBean b = new BaseBean();
                String sql = "SELECT abnormal_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from UF_ABNORMALSIGN  WHERE abnormal_date like '%" + month + "%' AND userid = " + id + "";
                RecordSet rs = new RecordSet();
                rs.execute(sql);
                //b.writeLog("异常考勤sql:"+sql);
                while (rs.next()) {
                    String abnormalDate = Util.null2String(rs.getString("abnormal_date"));//考勤异常日期
                    String morningSignIn = Util.null2String(rs.getString("morning_sign_in")); //上午签到考勤异常
                    String morningSignBack = Util.null2String(rs.getString("morning_sign_back")); //上午签退考勤异常
                    String afternoonSignIn = Util.null2String(rs.getString("afternoon_sign_in")); //下午签到考勤异常
                    String afternoonSignBack = Util.null2String(rs.getString("afternoon_sign_back")); //下午签退考勤异常
                    ////b.writeLog("当月集合:"+value);
                    List<String> abnormalSignDate=new LinkedList<String>();
                    if(value.containsKey(abnormalDate)){
                        abnormalSignDate = value.get(abnormalDate); //获取考勤异常当天的打卡时间集合
                    }
                    ////b.writeLog("当天异常日期："+abnormalDate+"异常数据:"+abnormalSignDate);
                    // 异常类型 上午签到 添加上午签到标准时间 上午签退 添加上午签退标准时间 下午签到 添加下午签到标准时间 下午签退 添加下午签退标准时间
                    if (morningSignIn.equals("1")) {
                        abnormalSignDate.add("08:30:00:1");
                        value.put(abnormalDate, abnormalSignDate);
                    }
                    if (morningSignBack.equals("1")) {
                        abnormalSignDate.add("11:45:00:2");
                        value.put(abnormalDate, abnormalSignDate);
                    }
                    if (afternoonSignIn.equals("1")) {
                        abnormalSignDate.add("13:00:00:1");
                        value.put(abnormalDate, abnormalSignDate);
                    }
                    if (afternoonSignBack.equals("1")) {
                        abnormalSignDate.add("17:15:00:2");
                        value.put(abnormalDate, abnormalSignDate);
                    }
                }
            }
        %>

        <!--改变请假(调休、年假)的打卡时间  -->
        <%!
            public static void changeLeaveTime(Map<String, List<String>> value, String id, String likeDate, int type, String leaveinFlag, String leaveoutFlag) {
                BaseBean b = new BaseBean();
                //全天标准打卡数据
                List<String> timeList1 = new ArrayList<String>();
                timeList1.add("08:30:00:"+leaveinFlag);
                timeList1.add("11:45:00:"+leaveoutFlag);
                timeList1.add("13:00:00:"+leaveinFlag);
                timeList1.add("17:15:00:"+leaveoutFlag);

                //上午上班、上午下班标准打卡数据
                List<String> timeList6 = new ArrayList<String>();
                timeList6.add("08:30:00:"+leaveinFlag);
                timeList6.add("11:45:00:"+leaveoutFlag);

                String sql = "SELECT start_date,start_time,end_date,end_time from uf_AskForLeave WHERE type = " + type + " AND userid = " + id + " and (start_date like '%" + likeDate + "%' or end_date like '%" + likeDate + "%') ORDER BY start_date";
                RecordSet rs = new RecordSet();
                rs.execute(sql);
                //b.writeLog("请假语句为:"+sql);
                while (rs.next()) {
                    //调休(年假)请假开始日期
                    String startDate = Util.null2String(rs.getString("start_date"));
                    //调休(年假)请假结束日期
                    String endDate = Util.null2String(rs.getString("end_date"));
                    //调休(年假)请假开始时间
                    String startTime = Util.null2String(rs.getString("start_time"));
                    //调休(年假)请假结束时间
                    String endTime = Util.null2String(rs.getString("end_time"));
                    List<String> wholeDate=findDates(startDate,endDate);
                    //请假日期不仅包括开始日期、结束日期，还包含其他日期 则需要对中间日期进行处理
                    if(wholeDate.size()>2){
                        for (String valueDate : wholeDate) {
                            if(!valueDate.equals(startDate)&&!valueDate.equals(endDate)){
                                String attendanceSql = "select attendancestatus from uf_attendance where curdate = '" + valueDate + "'";//根据日期查询排版表
                                int attendancestatus = getId(attendanceSql);
                                if (attendancestatus == 0) {
                                    //正常出勤1天
                                    value.put(valueDate, timeList1);
                                } else if (attendancestatus == 2) {
                                    //单休六出勤半天
                                    value.put(valueDate, timeList6);
                                }
                            }
                        }
                    }
                    //请假开始日期和请假结束日期不为同一天
                    if ((!startDate.equals(endDate))) {
                        //----2020.07.13---start---
                        //处理调休(年假)请假开始当天的考勤打卡时间
                        String startDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + startDate + "'";//根据日期查询排版表
                        int startDateStatus=getId(startDateStatusSql);
                        if(startDateStatus==0){
                            //正常出勤1天
                            endTime="17:15";
                            changeTodayTime(value, startTime, endTime, startDate,leaveinFlag,leaveoutFlag);
                        }else if(startDateStatus==2){
                            //单休六出勤半天
                            endTime="11:45";
                            changeSaturdayTime(value, startTime, endTime, startDate,leaveinFlag,leaveoutFlag);
                        }
                        //调休(年假)请假结束日期当天的打卡记录集合
                        String endDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                        int endDateStatus=getId(endDateStatusSql);
                        if(endDateStatus==0){
                            //正常出勤1天
                            startTime="08:30";
                            endTime=endTime.compareTo("17:15")>=0?"17:15":endTime;
                            changeTodayTime(value, startTime, endTime, endDate,leaveinFlag,leaveoutFlag);
                        }else if(endDateStatus==2){
                            //单休六出勤半天
                            startTime="08:30";
                            endTime=endTime.compareTo("11:45")>=0?"11:45":endTime;
                            changeSaturdayTime(value, startTime, endTime, endDate,leaveinFlag,leaveoutFlag);
                        }
                        //----2020.07.13---end---
                    } else {
                        //请假开始日期和请假结束日期为同一天
                        String attendanceSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                        int attendancestatus =getId(attendanceSql);
                        if(attendancestatus==0){
                            changeTodayTime(value, startTime, endTime, startDate,leaveinFlag,leaveoutFlag);//正常出勤1天
                        }else if(attendancestatus==2){
                            changeSaturdayTime(value, startTime, endTime, startDate,leaveinFlag,leaveoutFlag);//单休六出勤半天
                        }
                    }
                }
            }
        %>
        <!-- 处理周一到周五时间 -->
        <%!
            /**
             * 处理全天出勤的打卡集合
             * @param value
             * @param startTime
             * @param endTime
             * @param outdate
             * @param leaveinFlag
             * @param leaveoutFlag
             */
            public static void changeTodayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate,String leaveinFlag,String leaveoutFlag) {
                //处理外出当天的考勤打卡时间
                //外出当天的打卡记录集合
                BaseBean b = new BaseBean();
                List<String> gooutStartDate=new LinkedList<String>();
                //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
                if(value.containsKey(outdate)){
                    gooutStartDate = value.get(outdate);
                    Collections.sort(gooutStartDate);
                }
                int isNumber=gooutStartDate.size();//集合是否为空
                int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);

                int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

                //修改zcc 2020.06.20 ---start---
                startTime=startTime+":00:"+leaveinFlag;//将请假开始时间变成打卡签到时间
                startTime=startTime.compareTo("08:30:00:"+leaveinFlag)<=0?("08:30:00:"+leaveinFlag):startTime;
                endTime=endTime+":00:"+leaveoutFlag;//将请假结束时间变成打卡签退时间
                endTime=endTime.compareTo("17:15:00:"+leaveoutFlag)>=0?("17:15:00:"+leaveoutFlag):endTime;
                //b.writeLog("当天请假开始时间为:"+startTime+";当天请假结束时间为:"+endTime);
                //---end---

                //前提（结束时间一定大于开始时间）
                //1.外出开始时间小于等于8:30,外出结束时间小于等于8:30
                boolean result1 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) <= (8 * 60 + 30);
                //b.writeLog("result1结果为:" + result1);
                //2.外出开始时间小于等于8:30,外出结束时间小于11:45
                boolean result2 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) > (8 * 60 + 30);
                //b.writeLog("result2结果为:" + result2);
                //3.外出开始时间小于等于8:30,外出时间小于13:00
                boolean result3 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (11 * 60 + 45);
                //b.writeLog("result3结果为:" + result3);
                //4.外出开始时间小于等于8:30,外出时间小于17:15
                boolean result4 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) > (13 * 60);
                //b.writeLog("result4结果为:" + result4);
                //5.外出开始时间小于等于8:30,外出时间大于等于17:15
                boolean result5 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                //b.writeLog("result5结果为:" + result5);
                //6.外出开始时间小于11:45,外出结束时间小于11:45
                boolean result6 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) > (8 * 60 + 30);
                //b.writeLog("result6结果为:" + result6);
                //7.外出开始时间小于11:45,外出结束时间小于13:00
                boolean result7 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (11 * 60 + 45);
                //b.writeLog("result7结果为:" + result7);
                //8.外出开始时间小于11:45,外出结束时间小于17:15
                boolean result8 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (13 * 60);
                //b.writeLog("result8结果为:" + result8);
                //9.外出开始时间小于11:45,外出结束时间大于等于17:15
                boolean result9 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                //b.writeLog("result9结果为:" + result9);
                //10.外出开始时间小于13:15,外出结束时间小于13:00
                boolean result10 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) < (13 * 60);
                //b.writeLog("result10结果为:" + result10);
                //11.外出开始时间小于13:00,外出结束时间小于17:15
                boolean result11 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (13 * 60);
                //b.writeLog("result11结果为:" + result11);
                //12.外出开始时间小于13:00,外出结束时间大于等于17:15
                boolean result12 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                //b.writeLog("result12结果为:" + result12);
                //13.外出开始时间小于17:15,外出结束时间小于17:15
                boolean result13 = (startTimeForHours * 60 + startTimeForMinutes) > (13 * 60) && (startTimeForHours * 60 + startTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) > (13 * 60);
                //14.外出开始时间小于17:15,外出结束时间大于等于17:15
                boolean result14 = (startTimeForHours * 60 + startTimeForMinutes) > (13 * 60) && (startTimeForHours * 60 + startTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                //b.writeLog("result14结果为:" + result14);
                //15.外出开始时间大于等于17:15
                boolean result15 = (startTimeForHours * 60 + startTimeForMinutes) >= (17 * 60 + 15);
                //b.writeLog("result15结果为:" + result15);

                //外出当天打卡记录
                if (result2) {
                    //请假开始时间小于等于8:30,请假结束时间小于11:45
                    List<String> oldSignInList = new ArrayList<String>();//定义签到时间
                    if(isNumber>0){
                        //当天是否有打卡记录
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            //取出请假当天上午签到数据
                            if (signTime.endsWith("1") && signForHour < 12) {
                                oldSignInList.add(signTime);
                            }
                        }
                        String signInTime=oldSignInList.size() > 0?oldSignInList.get(0):"";//有打卡时间则取第一次签到时间 否则赋值为空
                        //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                        if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                            //修改zcc 2020.06.20 ---start---
                            gooutStartDate.add(startTime);
                            endTime=endTime.substring(0,9)+"2";
                            gooutStartDate.set(gooutStartDate.indexOf(signInTime),endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                    }else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate, gooutStartDate);
                    }
                    //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                } else if (result3) {
                    //外出开始时间小于等于8:30,外出时间小于13:00
                    gooutStartDate.add("08:30:00:"+leaveinFlag);
                    gooutStartDate.add("11:45:00:"+leaveoutFlag);
                    value.put(outdate, gooutStartDate);
                } else if (result4) {
                    //请假开始时间小于等于8:30,外出时间小于17:15
                    if(isNumber>0){
                        List<String> oldSignInList = new ArrayList<String>();//定义下午签到记录
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("1") && signForHour >= 12) {
                                oldSignInList.add(signTime);
                            }
                        }
                        String signInTime=oldSignInList.size() > 0?oldSignInList.get(0):"";//有打卡时间则取第一次签到时间 否则赋值为空
                        //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                        if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                            //修改zcc 2020.06.22 ---start---
                            gooutStartDate.add(startTime);
                            endTime=endTime.substring(0,9)+"2";
                            gooutStartDate.set(gooutStartDate.indexOf(signInTime),endTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }
                    }else{
                        //当天无打卡记录
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        gooutStartDate.add("11:45:00:"+leaveoutFlag);
                        gooutStartDate.add("13:00:00:"+leaveinFlag);
                        value.put(outdate, gooutStartDate);
                    }
                    //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                } else if (result5) {
                    //外出开始时间小于等于8:30,外出时间大于等于17:15
                    ////b.writeLog("标识1的值:"+leaveinFlag+"标识2的值:"+leaveoutFlag);
                    gooutStartDate.add("08:30:00:"+leaveinFlag);
                    gooutStartDate.add("11:45:00:"+leaveoutFlag);
                    gooutStartDate.add("13:00:00:"+leaveinFlag);
                    gooutStartDate.add("17:15:00:"+leaveoutFlag);
                    value.put(outdate, gooutStartDate);
                }else if(result6){
                    //外出开始时间小于11:45,外出结束时间小于11:45
                    if (value.containsKey(outdate)) {
                        for (int i = 0; i < gooutStartDate.size(); i++) {
                            if(gooutStartDate.size()==1){
                                //当天只有一个打卡时间
                                if(gooutStartDate.get(0).compareTo(startTime)>=0&&gooutStartDate.get(0).compareTo(endTime)<=0){
                                    gooutStartDate.remove(0);
                                    break;
                                }
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }else {
                                String time = gooutStartDate.get(i);
                                if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("2")) {
                                    //08:00:1   10:00:2  10:45:3  11:45:4
                                    if (time.compareTo(startTime) <= 0) {
                                        gooutStartDate.add(startTime);
                                        gooutStartDate.add(endTime);
                                    }
                                } else if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("1")) {
                                    //08:00:3   10:00:4  10:45:1  11:45:2
                                    if (time.compareTo(endTime) >= 0) {
                                        gooutStartDate.add(startTime);
                                        gooutStartDate.add(endTime);
                                    }
                                }
                            }
                        }
                    } else {
                        //当天无打卡记录
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }
                    value.put(outdate, gooutStartDate);
                } else if (result7) {
                    if(isNumber>0){
                        //当天有打卡记录
                        //请假开始时间小于11:45,请假结束时间小于13:00
                        List<String> oldSignOutList = new ArrayList<String>();//定义上午签退数据
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("2") && signForHour < 12) {
                                oldSignOutList.add(signTime);
                            }
                        }
                        String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取上午最后一条签退数据
                        endTime=(endTimeForHours*60+endTimeForMinutes)>11*60+45?("11:45:00:"+leaveoutFlag):endTime;
                        //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                        if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                            startTime=startTime.substring(0,9)+"1";
                            gooutStartDate.set(gooutStartDate.indexOf(signOutTime),startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                    }else{
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate, gooutStartDate);
                    }
                    //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                } else if (result8) {
                    if(isNumber>0){
                        //当天有打卡记录
                        //请假开始时间小于11:45,请假结束时间小于17:15
                        List<String> oldSignOutList = new ArrayList<String>();//定义上午签退数据
                        List<String> oldSignInList = new ArrayList<String>();//定义下午签到数据
                        //上午签退时间与请假开始时间相比 下午签到时间与请假结束时间相比
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("2") && signForHour < 12) {
                                oldSignOutList.add(signTime);
                            }
                            if (signTime.endsWith("1") && signForHour >= 12) {
                                oldSignInList.add(signTime);
                            }
                        }
//                        //b.writeLog("oldSignOutList集合为："+oldSignOutList);
//                        //b.writeLog("oldSignInList集合为："+oldSignInList);
                        String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                        String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间
                        //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime);
                        //b.writeLog("下午签到时间:"+signInTime+"请假结束时间:"+endTime);
                        //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                        if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                            startTime=startTime.substring(0,9)+"1";
                            gooutStartDate.set(gooutStartDate.indexOf(signOutTime),startTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                        }
                        //b.writeLog("请假开始时间与签退相比:"+gooutStartDate);
                        if(signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")){
                            //b.writeLog("endTime:--------"+endTime);
                            endTime=endTime.substring(0,9)+"2";
                            gooutStartDate.set(gooutStartDate.indexOf(signInTime),endTime);
                        }else{
                            gooutStartDate.add(endTime);
                        }
                        //b.writeLog("请假结束时间与签到相比:"+gooutStartDate);
                        //b.writeLog("当天日期为："+outdate+"打卡集合为："+gooutStartDate);
                        value.put(outdate,gooutStartDate);
                    }else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        gooutStartDate.add("11:45:00:"+leaveoutFlag);
                        gooutStartDate.add("13:00:00:"+leaveinFlag);
                        value.put(outdate,gooutStartDate);
                    }
                } else if (result9) {
                    if(isNumber>0){
                        //外出开始时间小于11:45,外出结束时间大于等于17:15
                        List<String> oldSignOutList = new ArrayList<String>();
                        //上午签退时间与开始时间比较
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("2") && signForHour < 12) {
                                oldSignOutList.add(signTime);
                            }
                        }
                        String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次上午签退时间
                        //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                        //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime+";两者比较:"+signOutTime.compareTo(startTime));
                        if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                            startTime=startTime.substring(0,9)+"1";
                            gooutStartDate.set(gooutStartDate.indexOf(signOutTime),startTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            gooutStartDate.add("11:45:00:"+leaveoutFlag);
                            gooutStartDate.add("13:00:00:"+leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }
                    }else{
                        //当天无打卡记录
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        gooutStartDate.add("11:45:00:"+leaveoutFlag);
                        gooutStartDate.add("13:00:00:"+leaveinFlag);
                        value.put(outdate, gooutStartDate);
                    }
                    ////b.writeLog("result9:"+result9+";当天日期:"+outdate+"当天打卡记录:"+gooutStartDate);
                } else if (result11) {
                    startTime="13:00:00:3";
                    if(isNumber>0){
                        //开始时间小于13:00,结束时间小于17:15
                        List<String> oldSignInList = new ArrayList<String>();
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("1") && signForHour >= 12) {
                                oldSignInList.add(signTime);
                            }
                        }
                        String signInTime = oldSignInList.size()>0?oldSignInList.get(0):"";//取第一次下午签到时间
                        //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                        if (signInTime.compareTo(endTime) <= 0&& !signInTime.equals("")) {
                            gooutStartDate.add(startTime);
                            endTime=endTime.substring(0,9)+"2";
                            gooutStartDate.set(gooutStartDate.indexOf(signInTime),endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                    }else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate,gooutStartDate);
                    }
                } else if (result12) {
                    if(gooutStartDate.size()!=0){
                        for(int i=0;i<gooutStartDate.size();i++){
                            if(getTimeMin(gooutStartDate.get(i).substring(0,5))>=720&&getTimeMin(gooutStartDate.get(i).substring(0,5))<=1035){
                                gooutStartDate.remove(gooutStartDate.get(i));
                            }
                        }
                    }
                    gooutStartDate.add("13:00:00:" + leaveinFlag);
                    gooutStartDate.add("17:15:00:" + leaveoutFlag);
                    value.put(outdate, gooutStartDate);
                }  else if (result13) {
                    if (isNumber > 0) {
                        //当天有打卡集合
                        //接收下午签退及请假结束数据
                        List<String> oldSignOutList = new ArrayList<String>();
                        //接收下午签到数据
                        List<String> oldSignInList = new ArrayList<String>();    
                        if(gooutStartDate.size()==1){ 
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                        }else {
                            //当天有两个及以上打卡记录
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                                if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                                    oldSignOutList.add(signTime);
                                }
                                if ((signTime.endsWith("1")||signTime.endsWith("3")||signTime.endsWith("5")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                                    oldSignInList.add(signTime);
                                }
                            }
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                            //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                            if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.add(startTime);
                            } else if(signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")){
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.add(endTime);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }
                        }
                        value.put(outdate, gooutStartDate);
                    } else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate, gooutStartDate);
                    }
                } else if (result14) {
                    endTime="17:15:00:"+leaveoutFlag;
                    if(isNumber>0){
                        //外出开始时间小于17:15,外出结束时间大于等于17:15
                        List<String> oldSignOutList = new ArrayList<String>();
                        b.writeLog("当天打卡记录为：" + gooutStartDate);
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                            if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                                oldSignOutList.add(signTime);
                            }
                        }
                        b.writeLog("dateList请假13：15--17：15>>>>>" + oldSignOutList);
                        String signOutTime = oldSignOutList.size() > 0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取最后一次下午签退时间
                        //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                        if (signOutTime.compareTo(startTime) >= 0&& !signOutTime.equals("")) {
                            startTime=startTime.substring(0,9)+"1";
                            gooutStartDate.set(gooutStartDate.indexOf(signOutTime),startTime);
                            gooutStartDate.add(endTime);
                            b.writeLog("gooutStartDate5>>>>>" + gooutStartDate);
                            value.put(outdate, gooutStartDate);
                            b.writeLog("value>>>>>" + value);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate,gooutStartDate);
                        }
                    }else {
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate,gooutStartDate);
                    }
                }
            }
        %>
        <!-- 处理当天(周六)时间 -->
        <%!
            /**
             * 处理上午半天出勤的打卡集合
             * @param value
             * @param startTime
             * @param endTime
             * @param outdate
             * @param leaveinFlag
             * @param leaveoutFlag
             */
            public static void changeSaturdayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate,String leaveinFlag,String leaveoutFlag) {
                //周六当天的打卡记录集合
                List<String> gooutStartDate=new LinkedList<String>();
                //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
                if(value.containsKey(outdate)){
                    gooutStartDate = value.get(outdate);
                    Collections.sort(gooutStartDate);
                }
                int isNumber=gooutStartDate.size();//集合是否为空
                int startTimeForMinutes = getTimeMin(startTime);//开始时间对应的分钟数
                int endTimeForMinutes = getTimeMin(endTime);//结束时间对应的分钟数
                //修改zcc 2020.06.20 ---start---
                startTime=startTime+":00:"+leaveinFlag;//将请假开始时间变成打卡签到时间
                startTime=startTime.compareTo("08:30:00:"+leaveinFlag)<=0?("08:30:00:"+leaveinFlag):startTime;
                endTime=endTime+":00:"+leaveoutFlag;//将请假结束时间变成打卡签退时间
                endTime=endTime.compareTo("11:45:00:"+leaveoutFlag)>=0?("11:45:00:"+leaveoutFlag):endTime;

                //---end---
                //1.开始时间小于等于8:30,外出结束时间小于11:45
                boolean result1 = startTimeForMinutes <= (8 * 60 + 30) && endTimeForMinutes < (11 * 60 + 45);
                //2.开始时间小于等于8:30,外出时间大于等于11:15
                boolean result2 = startTimeForMinutes <= (8 * 60 + 30) && endTimeForMinutes >= (11 * 60 + 45);
                //3.开始时间小于11：45,结束时间小于11：45
                boolean result3 = startTimeForMinutes > (8 * 60 + 30) && startTimeForMinutes < (11 * 60 + 45) && endTimeForMinutes > (8 * 60 + 30) && endTimeForMinutes < (11 * 60 + 45);
                //4.开始时间小于11:45,外出结束时间大于等于11:45
                boolean result4 = startTimeForMinutes > (8 * 60 + 30) && startTimeForMinutes < (11 * 60 + 45) && endTimeForMinutes >= (11 * 60 + 45);

                //当天打卡记录
                if (result1) {
                    if(isNumber>0){
                        //请假开始时间小于等于8:30,请假结束时间小于11:45
                        List<String> oldSignInList = new ArrayList<String>();//定义签到时间
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            //取出请假当天上午签到数据
                            if (signTime.endsWith("1") && signForHour < 12) {
                                oldSignInList.add(signTime);
                            }
                        }
                        String signInTime=oldSignInList.size() > 0?oldSignInList.get(0):"";//有打卡时间则取第一次签到时间 否则赋值为空
                        //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                        if (signInTime.compareTo(endTime) <= 0) {
                            gooutStartDate.add(startTime);
                            endTime=endTime.substring(0,9)+"2";
                            gooutStartDate.set(gooutStartDate.indexOf(signInTime),endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate,gooutStartDate);
                        }
                    }else{
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate,gooutStartDate);
                    }
                } else if (result2) {
                    gooutStartDate.add("08:30:00:"+leaveinFlag);
                    gooutStartDate.add("11:45:00:"+leaveoutFlag);
                    value.put(outdate, gooutStartDate);
                } else if (result3){
                    if (value.containsKey(outdate)) {
                        for (int i = 0; i < gooutStartDate.size(); i++) {
                            if(gooutStartDate.size()==1){
                                //当天只有一个打卡时间
                                if(gooutStartDate.get(0).compareTo(startTime)>=0&&gooutStartDate.get(0).compareTo(endTime)<=0){
                                    gooutStartDate.remove(0);
                                    break;
                                }
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                            }else {
                                String time = gooutStartDate.get(i);
                                if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("2")) {
                                    //08:00:1   10:00:2  10:45:3  11:45:4
                                    if (time.compareTo(startTime) <= 0) {
                                        gooutStartDate.add(startTime);
                                        gooutStartDate.add(endTime);
                                    }
                                } else if (Integer.parseInt(time.substring(0, 2)) < 12 && time.endsWith("1")) {
                                    //08:00:3   10:00:4  10:45:1  11:45:2
                                    if (time.compareTo(endTime) >= 0) {
                                        gooutStartDate.add(startTime);
                                        gooutStartDate.add(endTime);
                                    }
                                }
                            }
                        }
                    } else {
                        //当天无打卡记录
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                    }
                    value.put(outdate, gooutStartDate);
                } else if (result4) {
                    if(isNumber>0){
                        //开始时间小于11:45,结束时间大于等于11:45
                        List<String> oldSignOutList = new ArrayList<String>();//定义上午签退数据
                        for (String signTime : gooutStartDate) {
                            int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                            if (signTime.endsWith("2") && signForHour < 12) {
                                oldSignOutList.add(signTime);
                            }
                        }
                        String signOutTime = oldSignOutList.size()>0?oldSignOutList.get(oldSignOutList.size() - 1):"";//取上午最后一条签退数据
                        //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                        if (signOutTime.compareTo(startTime) >= 0) {
                            startTime=startTime.substring(0,9)+"1";
                            gooutStartDate.set(gooutStartDate.indexOf(signOutTime),startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }else{
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate,gooutStartDate);
                        }
                    }else{
                        gooutStartDate.add(startTime);
                        gooutStartDate.add(endTime);
                        value.put(outdate,gooutStartDate);
                    }
                }
            }
        %>

        <!--处理上月底至本月初的请假数据-->
        <%!
            public static Double getLeaveTime(int num1, String month, String workCode) {
                Double cnt7 = 0.0;
                String leaveSql1 = " select end_date,end_time from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') and " +
                        " type=" + num1 + " and start_date not like '%" + month + "%' and end_date like '%" + month + "%' ";
                RecordSet recordSet1 = new RecordSet();
                recordSet1.execute(leaveSql1);
                ////b.writeLog("处理上月底至本月初的请假数据："+leaveSql1);
                if (recordSet1.next()) {
                    String sDate = month + "-01";
                    String endDate = recordSet1.getString(1);
                    String endTime = recordSet1.getString(2);
                    //查询出月初至截止请假日期（不包含截止请假日期）的请假数据
                    String combineSql = "SELECT case when count(*) is null then 0 else count(*)*7.5 end from uf_attendance where curdate>='" + sDate + "'  and curdate<'" + endTime + "' " +
                            "and attendancestatus=0 union all SELECT case when count(*) is null then 0 else count(*)*3.25 end  from uf_attendance where curdate>='" + sDate + "'  and curdate<'" + endTime + "' " +
                            "and attendancestatus=2 ";
                    RecordSet recordSet2 = new RecordSet();
                    recordSet2.execute(combineSql);
                    ////b.writeLog("查询出月初至截止请假日期（不包含截止请假日期）的请假数据"+combineSql);
                    while (recordSet1.next()) {
                        String s1 = recordSet2.getString(1);
                        cnt7 += Double.parseDouble(s1);
                    }
                    //查询出截止请假日期当天的请假数据
                    cnt7 += getHour(endDate, endTime);
                }
                return cnt7;
            }
        %>
        <!--查询出截止请假日期当天的请假数据-->
        <%!
            public static Double getHour(String endDate, String endTime) {
                double cnt8 = 0.0;
                String endDateSql = "select attendancestatus from uf_attendance where curdate='" + endDate + "'  ";
                int attendanceStatus=getId(endDateSql);
                int endMin = Integer.parseInt(endTime.substring(0, 2)) * 60 + Integer.parseInt(endTime.substring(3, 5));
                final boolean b = endMin >= 8 * 60 + 30 && endMin < 11 * 60 + 45;
                if (attendanceStatus== 0) {
                    if (b) {
                        cnt8 += Double.parseDouble(getDifferenceHours("08:30",endTime));

                    } else if (endMin >= 11 * 60 + 45 && endMin <= 13 * 60 + 15) {
                        cnt8 += 3.25;
                    } else if (endMin > 13 * 60 + 15 && endMin < 17 * 60 + 15) {
                        cnt8 += Double.parseDouble(getDifferenceHours("09:45",endTime));
                    } else if (endMin >= 17 * 60 + 15) {
                        cnt8 += 7.25;
                    }
                } else if (attendanceStatus== 2) {
                    if (b) {
                        cnt8 += Double.parseDouble(getDifferenceHours("08:30",endTime));
                    } else if (endMin >= 11 * 60 + 45) {
                        cnt8 += 3.25;
                    }
                }
                return cnt8;
            }
        %>

        <!--查询出截止请假日期当天的请假数据-->
        <%!
            public static Double getNewHour(String startDate, String startTime) {
                double cnt8 = 0.0;
                String startDateSql = "select attendancestatus from uf_attendance where curdate='" + startDate + "'  ";
                int attendanceStatus=getId(startDateSql);
                int startMin = Integer.parseInt(startTime.substring(0, 2)) * 60 + Integer.parseInt(startTime.substring(3, 5));
                final boolean b = startMin >= 8 * 60 + 30 && startMin < 11 * 60 + 45;
                if (attendanceStatus == 0) {
                    if (b) {
                        cnt8 += Double.parseDouble(getDifferenceHours("08:30",startTime));
                    } else if ((startMin >= ((11 * 60) + 45)) && (startMin <= ((13 * 60) + 15))) {
                        cnt8 += 3.25;
                    } else if ((startMin > ((13 * 60) + 15)) && (startMin < ((17 * 60) + 15))) {
                        cnt8 += Double.parseDouble(getDifferenceHours("09:45",startTime));
                    } else if (startMin >= ((17 * 60) + 15)) {
                        cnt8 += 7.50;
                    }
                } else if (attendanceStatus == 2) {
                    if (b) {
                        cnt8 += Double.parseDouble(getDifferenceHours("08:30",startTime));
                    } else if (startMin >= 11 * 60 + 45) {
                        cnt8 += 3.25;
                    }
                }
                return cnt8;
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
    </table>
</div>
</body>