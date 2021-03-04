<!-- 门店考勤月报表 -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="weaver.conn.RecordSet" %>
<%@ page import="weaver.iiot.grouptow.common.*" %>
<%@ page import="weaver.iiot.grouptow.util.AttendanceUtil" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="weaver.iiot.grouptow.common.entity.AttendanceOption" %>
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
            LeaveCommonController leaveCommonController = new LeaveCommonController();
            AbnormalCommonController abnormalCommonController = new AbnormalCommonController();
            BusinessCommonController businessCommonController = new BusinessCommonController();
            CurdayContionController curdayContionController = new CurdayContionController();
            FinalTimeListController finalTimeListController = new FinalTimeListController();
            AttendanceUtil attendanceUtil = new AttendanceUtil();
            List<String> abnormalList=new LinkedList<String>();
            //查询当月应出勤日期 周一至周五
            List<String> curdateList = new ArrayList<String>();
            List<String> curdateList1 = new ArrayList<String>();//用于接收当前日期存在打卡记录的集合
            String curdateSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus like '0%'";
            RecordSet rs6 = new RecordSet();
            rs6.execute(curdateSql);
            while (rs6.next()) {
                String curdate = rs6.getString(1);
                curdateList.add(curdate);
            }
            //查询当月应出勤日期 周六  //2020.04.19 zcc查出事假，赋值当天旷工为0.5 确认 事假小时数/7.5*0.5
            List<String> saturdayList = new ArrayList<String>();
            List<String> saturdayList1 = new ArrayList<String>();//用于接收当前存在打卡记录的集合
            String saturdayForWorkSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus like '2%'";
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
            Map<String,Map<String,List<String>>> areaResult = attendanceUtil.getAreaResult(sql);
            //b.writeLog("areaResult："+areaResult);
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

                    //调用方法，改变出差时的打卡时间
                    businessCommonController.changeBusinessTripTime(value,checkMinDate,checkMaxDate,id,month,"1","2");

                    //调用方法，改变异常考勤时的打卡时间
                    abnormalCommonController.changeAbnormalSignTime(value,id,month);

                    //调用方法，改变请假(调休)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,8,"3","4");

                    //调用方法，改变请假(年假)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,0,"3","4");

                    //调用方法，改变请假(事假)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,9,"5","6");
                    b.writeLog("请假处理后:"+value);
                    //判断value集合是否为空
                    if(value.size()>0){
                        //获取结果集所有键的集合，用keySet()方法实现
                        Set<String> valueSet = value.keySet();
                        //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
                        TreeSet<String> ts_set = attendanceUtil.getDateTreeSet();
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

                                //调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
                                List<String> finalTimeList = finalTimeListController.getFinalTimeList(timeList);
                                b.writeLog("当前日期:>>>" + curdate + "对应打卡记录:>>>" + finalTimeList);
                                //对哺乳假数据进行处理
                                List<String> newFinalTimeList = finalTimeListController.reviseFinalTimeList(finalTimeList, curdate, id);
                                //b.writeLog("当前日期:>>>" + curdate + "对应打卡记录:>>>" + newFinalTimeList);
                                double count = 0.0;
                                if(curdateList.contains(curdate)){
                                    ////b.writeLog("--------------------------------------2020.06.28---");
                                    List<String> morningList1=new LinkedList<String>();
                                    List<String> afternoonList1=new LinkedList<String>();
                                    for (String time5:newFinalTimeList){
                                        int time5ForMin= attendanceUtil.getTimeMin(time5);
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
                                    List<String> afternoonList1=new LinkedList<String>();
                                    for (String time5:newFinalTimeList){
                                        int time5ForMin= attendanceUtil.getTimeMin(time5);
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
                                        if(time6.endsWith("1")&&(time6.compareTo("16:15:00:1")>0)){
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
                                    saturdayList1.add(curdate);
                                    if(count !=0.0){
                                        abnormalList.add(curdate);
                                    }
                                }
                                if(abnormalList.contains(curdate)){
                                    out.println("<td id='td1'>");
                                }else{
                                    out.println("<td>");
                                }

                                for(String time6:newFinalTimeList){
                                    int signtimeForMin=Integer.parseInt(time6.split(":")[0])*60+Integer.parseInt(time6.split(":")[1]);
                                    String attendanceStatus= attendanceUtil.getAttendanceStatus(curdate).getAttendanceStatus();
                                    if(attendanceStatus.startsWith("0")){
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
                                    }else if(attendanceStatus.startsWith("2")){
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
                                                if(signtimeForMin<16*60+15){
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
                                    }else if(attendanceStatus.startsWith("1")){
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

    </table>
</div>
</body>