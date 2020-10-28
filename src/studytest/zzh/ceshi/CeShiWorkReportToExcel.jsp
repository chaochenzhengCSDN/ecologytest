<!-- 门店考勤月报表 -->
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@page import="weaver.conn.RecordSet"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ page import="java.text.DecimalFormat" %>

<jsp:useBean id="ResourceComInfo" class="weaver.hrm.resource.ResourceComInfo" scope="page" />
<%
    String month = request.getParameter("month");
    //获取部门ID
    String departId = request.getParameter("departId");
    //获取员工编号
    String userCode = request.getParameter("userCode");

    String result[] = month.split("-");
    String month2 = result[1];
    String year2 = result[0];
    int month3 = Integer.parseInt(month2);
    int year3 = Integer.parseInt(year2);

    String curdate1 = year2+"-"+month2;
    String ysdate = curdate1+"-01";
    String yedate = curdate1+"-31";
    //获取日历类对象
    Calendar c = Calendar.getInstance();
    c.set(year3,month3-1,1);
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    String checkMinDate = sdf.format(c.getTime());
    c.add(Calendar.MONTH,+1);
    c.add(Calendar.DATE,-1);
    String checkMaxDate = sdf.format(c.getTime());
    int maxDateDays = c.get(Calendar.DATE);

    c.add(Calendar.MONTH,-1);
    String defaultStartDate = sdf.format(c.getTime());

    c.add(Calendar.MONTH,2);
    String defaultEndDate = sdf.format(c.getTime());

	String fileName = month+"月份考勤报表";
	response.setContentType("application/vnd.ms-excel");
	response.setHeader("Content-disposition","attachment;filename="+new String(fileName.getBytes("GBK"),"iso8859-1")+".xls");

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
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
    </style>
</head>
<body>
<div id="div1">
    <table width="2000px" border="1" cellpadding="0" cellspacing="0">
        <tr>
            <td align='center' rowspan=2><b>公司</b></td>
            <td align='center' rowspan=2><b>部门</b></td>
            <td align='center' rowspan=2><b>姓名</b></td>
            <td align='center' rowspan=2><b>工号</b></td>
            <td align='center' rowspan=2><b>月份</b></td>
            <td align='center' rowspan=2><b>应出勤（天）</b></td>
            <td align='center' rowspan=2><b>实出勤（天）</b></td>
            <td align='center' rowspan=2><b>法定节假日</b></td>
            <td align='center' rowspan=2><b>基本工时</b></td>
            <td align='center' rowspan=2><b>迟到（分）</b></td>
            <td align='center' rowspan=2><b>早退（分）</b></td>
            <td align='center' rowspan=2><b>旷工（天）</b></td>
            <td align='center' colspan=5><b>请假（天）</b></td>
            <td align='center' colspan=3><b>加班（小时）</b></td>
            <td align='center' rowspan=2><b>异常流程次数</b></td>
            <td align='center' rowspan=2><b>剩余调休时间</b></td>
            <td align='center' colspan=3><b>年假</b></td>
        </tr>
        <tr>
            <td align='center'><b>年休假</b></td>
            <td align='center'><b>婚假</b></td>
            <td align='center'><b>产假</b></td>
            <td align='center'><b>调休</b></td>
            <td align='center'><b>事假</b></td>
            <td align='center'><b>加点工时</b></td>
            <td align='center'><b>加班工时</b></td>
            <td align='center'><b>调休工时</b></td>
            <td align='center'><b>总共</b></td>
            <td align='center'><b>已用</b></td>
            <td align='center'><b>可用</b></td>
        </tr>
                <%
                    //基本工时  周一至周五
                    String selectSql1 = "select count(*) from uf_attendance where week<6 and isAttendance=0 and isholiday=1 and CURDATE like '%" + month + "%'  ";
                    RecordSet rs2 = new RecordSet();
                    rs2.executeSql(selectSql1);
                    rs2.next();
                    int cnt2 = rs2.getInt(1);
                    //基本工时  周六工作日
                    String selectSql2 = "select count(*) from uf_attendance where week=6 and isAttendance=0 and isholiday=1 and CURDATE like '%" + month + "%'  ";
                    RecordSet rs3 = new RecordSet();
                    rs3.executeSql(selectSql2);
                    rs3.next();
                    int cnt3 = rs3.getInt(1);
                    double basicWorkTime = (cnt2 * 7.5 + cnt3 * 6.5);
                    List<Integer> typeList = new ArrayList();
                    typeList.add(0,0);
                    typeList.add(1,1);
                    typeList.add(2,2);
                    typeList.add(3,8);
                    typeList.add(4,9);
                    //typeList.add(5,11);
                    //查询当月应出勤日期 周一至周五
                    List<String> curdateList = new ArrayList<String>();
                    String curdateSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and isattendance=0 and isholiday=1 and week<=5";
                    RecordSet rs6 = new RecordSet();
                    rs6.executeSql(curdateSql);
                    while (rs6.next()) {
                        String curdate = rs6.getString(1);
                        curdateList.add(curdate);
                    }
                    //查询当月应出勤日期 周六  //2020.04.19 zcc查出事假，赋值当天旷工为0.5 确认 事假小时数/7.5*0.5
                    List<String> saturdayList = new ArrayList<String>();
                    String saturdayForWorkSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and isattendance=0 and isholiday=1 and week=6";
                    RecordSet rs7 = new RecordSet();
                    rs7.executeSql(saturdayForWorkSql);
                    while (rs7.next()) {
                        String curdate = rs7.getString(1);
                        saturdayList.add(curdate);
                    }
                    String sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname,hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType,hre.id," +
                            "(SELECT COUNT( isAttendance ) FROM uf_attendance WHERE curdate BETWEEN '"+ysdate+"' AND '"+yedate+"' AND isAttendance = 0) AS days,(SELECT COUNT( isholiday ) FROM uf_attendance " +
                            " WHERE curdate BETWEEN '"+ysdate+"' AND '"+yedate+"' AND isholiday = 0) AS holiday  FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id = hsc.userid AND hsc.signDate " +
                            "BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid=hde.id WHERE hre.accounttype !=1 and hre.workCode LIKE '%"+userCode+"%'";
                    if("".equals(departId) || departId==null){}else{
                        sql+="AND EXISTS (SELECT 1 FROM hrmdepartment WHERE id in ( "+departId+" ) AND id = hre.departmentid)";
                    }
                    sql+="AND CASE WHEN hre.startdate is NULL THEN '"+checkMaxDate+"' ELSE hre.startdate END <= '"+checkMaxDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+checkMinDate+"' ELSE hre.enddate END >= '"+checkMinDate+"' ORDER BY hde.id,hsc.signDate ASC";
                    //定义集合，把数据进行封装
                    Map<String,Map<String,List<String>>> areaResult = getAreaResult(sql);
                    //判断获取的数据是否为空
                    if(areaResult!=null && areaResult.size()>0){
                    //获取结果集所有键的集合，用keySet()方法实现
                    Set<String> keySet = areaResult.keySet();
                    //遍历键的集合，获取到每一个键。用增强for实现
                    for (String key : keySet) {
                        Double countAll = 0.0;//记录总矿工天数
                        Double count = 0.0;//记录周一至周五矿工天数
                        Double earlyTime = 0.0;//记录早退分钟数
                        Double lateTime = 0.0;//记录迟到分钟数
                        String subcompanyname = key.split(",")[0];
                        String departmentname = key.split(",")[1];
                        String workCode = key.split(",")[2];
                        String lastname = key.split(",")[3];
                        String id = key.split(",")[4];
                        String days = key.split(",")[5];
                        String holiday = key.split(",")[6];
                        out.println("<tr>");
                        out.println("<td align='center'>" + subcompanyname + "</td>");//公司
                        out.println("<td align='center'>" + departmentname + "</td>");//部门
                        out.println("<td align='center'>" + lastname + "</td>");//姓名
                        out.println("<td align='center'>" + workCode + "</td>");//工号
                        out.println("<td align='center'>" + month + "</td>");//月份
                        out.println("<td align='center'>" + days + "</td>");//应出勤
                        //实出勤天数
                        String realAttendanceSql = "SELECT COUNT (DISTINCT(h2.signdate)) AS 出勤天数 FROM hrmschedulesign h2 LEFT JOIN hrmresource h1 ON h1.ID = h2.userId " +
                                " WHERE h1.workcode like '%" + workCode + "%' AND h2.signdate LIKE '%" + month + "%' and h1.accounttype=0 and h2.isincom=1 ";
                        RecordSet rs1 = new RecordSet();
                        rs1.executeSql(realAttendanceSql);
                        rs1.next();
                        int cnt1 = rs1.getInt(1);
                        out.println("<td align='center'>" + cnt1 + "</td>");//实出勤
                        out.println("<td align='center'>" + holiday + "</td>");//节假日
                        out.println("<td align='center'>" + basicWorkTime + "</td>");//基本工时

                        //根据键去找值，用get(Object key)方法实现
                        Map<String, List<String>> value = areaResult.get(key);
                        Map<String, List<String>> resultValue = new HashMap<String, List<String>>();
                        //调用方法，改变出差时的打卡时间
                        changeBusinessTripTime(value, checkMinDate, checkMaxDate, id,month);
                        //调用方法，改变外出时的打卡时间
                        changeGoOutTime(value, id,month);
                        //调用方法，改变异常考勤时的打卡时间
                        changeAbnormalSignTime(value, id,month);
                        //调用方法，改变请假(调休)的打卡时间
                        changeLeaveTime(value, checkMinDate, checkMaxDate, id,month, 8);
                        //调用方法，改变请假(年假)的打卡时间
                        changeLeaveTime(value, checkMinDate, checkMaxDate, id,month, 0);
                        //调用方法，改变请假(事假)的打卡时间
                        changeLeaveTime(value, checkMinDate, checkMaxDate, id,month, 9);
                        //判断value集合是否为空
                        if (value.size() > 0) {
                            //获取结果集所有键的集合，用keySet()方法实现
                            Set<String> valueSet = value.keySet();
                            //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
                            TreeSet<String> ts1 = getDateTreeSet();
                            ts1.addAll(valueSet);
                            //遍历键的集合，获取到每一个键。用增强for实现
                            Map<String,List<String>> map1=new LinkedHashMap<String, List<String>>();
                            for (String key1 : ts1) {
                                if (Integer.parseInt(key1.split("-")[1]) == Integer.parseInt(month.split("-")[1])) {
                                    String day1 = key1.split("-")[2];
                                    //根据键去找值，用get(Object key)方法实现
                                    List<String> timeList = value.get(key1);
                                    //调用getTimeTreeSet()方法对HH:mm:ss格式时间进行排序
                                    TreeSet<String> ts2 = getTimeTreeSet();
                                    //for循环遍历timeList集合
                                    for (int i = 0; i < timeList.size(); i++) {
                                        String s = timeList.get(i);
                                        ts2.add(s);
                                    }
                                    //调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
                                    List<String> morningTimeList = getMorningTimeList(ts2);
                                    //调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
                                    List<String> afternoonTimeList = getAfternoonTimeList(ts2);
                                    //调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
                                    List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);
                                    //调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
                                    List<String> finalTimeList = getFinalTimeList(morningTimeList, afternoonTimeList, confirmTimeList);
                                    map1.put(key1,finalTimeList);
                                }
                            }
                            //计算当月缺勤天数
                            for (String key3 : map1.keySet()) {
                            List<String> finalTimeList = map1.get(key3);
                            //应出勤的日期有打卡记录 去除并记录无考勤记录的日期
                            for (int m = 0; m < curdateList.size(); m++) {
                                for (int j = 0; j < curdateList.size(); j++) {
                                    if (curdateList.get(j).equals(key3)) {
//                                        computeDailyLateAndEarlyTime(finalTimeList, count, lateTime, earlyTime);
                                        int collectionSize=finalTimeList.size();//打卡时间集合大小
                                        //判断是否有加班时间 如果有下午加班时间 设置新的集合长度
                                        for(String time:finalTimeList){
                                            int min=Integer.parseInt(time.substring(0,2))*60+Integer.parseInt(time.substring(3,5));
                                            int index=0;
                                            if(time.endsWith("2")&&min>12*60){
                                                index++;
                                            }
                                            if(index>1){
                                                collectionSize =collectionSize-index+1;
                                            }
                                        }
                                        if (collectionSize <= 1) {
                                            count++;
                                        } else if (collectionSize == 2) {
                                            /**
                                             * 两次记录
                                             * 上午签到 上午签退 result1
                                             * 上午签到 下午签到 result2
                                             * 上午签到 下午签退 result3
                                             * 上午签退 下午签到 result4
                                             * 上午签退 下午签退 result5
                                             * 下午签到 下午签退 result6
                                             */
                                            String time1=finalTimeList.get(0);
                                            String time2=finalTimeList.get(1);
                                            int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                                            int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                                            int result1=time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60?1:0;
                                            int result2=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60)||(time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2>12*60)||
                                                    (time1.endsWith("2")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60)||(time1.endsWith("2")&&min1<12*60&&time2.endsWith("2")&&min2>12*60))?1:0;
                                            int result3=time1.endsWith("1")&&min1>=12*60&&time2.endsWith("2")&&min2>=12*60?1:0;
                                            if(result1==1){
                                                if(min1>=9*60||min2<=11*60+15){
                                                    count++;
                                                }else{
                                                    if(min1>8*60+30&&min1<9*60){
                                                        lateTime +=min1 - 8 * 60 - 30;
                                                    }
                                                    if(min2>11*60+15&&min2<11*60+45){
                                                        earlyTime +=11*60 + 45 - min2;
                                                    }
                                                    count +=0.5;
                                                }
                                            }
                                            if(result2==1){
                                                count++;
                                            }
                                            if(result3==1){
                                                if(min1>=13*60+45||min2<=16*60+45){
                                                    count++;
                                                }else{
                                                    if(min1>13*60+15&&min1<13*60+45){
                                                        lateTime +=min1-13*60-15;
                                                    }
                                                    if(min2>16*60+45&&min2<17*60+15){
                                                        earlyTime +=17*60+15-min2;
                                                    }
                                                    count +=0.5;
                                                }
                                            }
                                        } else if (collectionSize == 3) {
                                            /**
                                             * 三次打卡记录
                                             * 上午签到 上午签退 下午签到 result1
                                             * 上午签到 上午签退 下午签退 result2
                                             * 上午签到 下午签到 下午签退 result3
                                             * 上午签退 下午签到 下午签退 result4
                                             */
                                            String time1=finalTimeList.get(0);
                                            String time2=finalTimeList.get(1);
                                            String time3=finalTimeList.get(2);
                                            int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                                            int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                                            int min3 = Integer.parseInt(time3.substring(0, 2)) * 60 + Integer.parseInt(time3.substring(3, 5));
                                            int result1=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60&&time3.endsWith("1")&&min3>=12*60)||
                                                    (time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60&&time1.endsWith("2")&&min3>=12*60))?1:0;
                                            int result2=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60&&time3.endsWith("2")&&min3>=12*60)||
                                                    (time1.endsWith("2")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60&&time3.endsWith("2")&&min3>=12*60))?1:0;
                                            if(result1==1){
                                                if(min1>=9*60||min2<=11*60+15){
                                                    count++;
                                                }else{
                                                    if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                                                        lateTime += min1 - 8 * 60 - 30;
                                                    }
                                                    if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                                                        earlyTime += 11 * 60 + 45 - min2;
                                                    }
                                                    count += 0.5;
                                                }
                                            }
                                            if(result2==1){
                                                if(min2>=13*60+45||min3<=16*60+45){
                                                    count++;
                                                }else{
                                                    if(min2>13*60+15&&min2<13*60+45){
                                                        lateTime +=min2-13*60-15;
                                                    }
                                                    if(min3>16*60+45&&min3<17*60+15){
                                                        earlyTime +=17*60+15-min3;
                                                    }
                                                    count +=0.5;
                                                }
                                            }
                                        } else if (collectionSize == 4) {
                                            String time1=finalTimeList.get(0);
                                            String time2=finalTimeList.get(1);
                                            String time3=finalTimeList.get(2);
                                            String time4=finalTimeList.get(3);
                                            int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));//上午签到时间对应的分钟数
                                            int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));//上午签退时间对应的分钟数
                                            int min3 = Integer.parseInt(time3.substring(0, 2)) * 60 + Integer.parseInt(time3.substring(3, 5));//下午签到时间对应的分钟数
                                            int min4 = Integer.parseInt(time4.substring(0, 2)) * 60 + Integer.parseInt(time4.substring(3, 5));//下午签退时间对应的分钟数
                                            //计算迟到早退小时数
                                            if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                                                lateTime += min1 - 8 * 60 - 30;
                                            }
                                            if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                                                earlyTime += 11 * 60 + 45 - min2;
                                            }
                                            if(min3>13*60+15&&min3<13*60+45){
                                                lateTime +=min3-13*60-15;
                                            }
                                            if(min4>16*60+45&&min4<17*60+15){
                                                earlyTime +=17*60+15-min4;
                                            }
                                            /**
                                             * 打卡记录有3次及以上超过规定时间的半个小时 计算旷工
                                             */
                                            if((min1>=9*60&&min2<=11*60+15)||(min3>=13*60+45&&min4<=16*60+45)){
                                                count +=0.5;
                                            }else if((min1>=9*60&&min3>=13*60+45)||(min1>=9*60&&min4<=16*60+45)||
                                                    (min2<=11*50+15&&min3>=13*60+45)||(min2<=11*60+15&&min4<=16*60+45)){
                                                count++;
                                            }else{
                                                if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
//                                                    lateTime += min1 - 8 * 60 - 30;
                                                }else if(min1 >= 9 * 60){
                                                    count +=0.5;
                                                }
                                                if(min2>11*60+15&&min2<11*60+45){
//                                                    earlyTime +=11*60+45-min4;
                                                }else if(min2 <= 11*60+15 ){
                                                    count += 0.5;
                                                }
                                                if(min3>13*60+15&&min3<13*60+45){
//                                                    lateTime +=min3-13*60-15;
                                                }else if(min3 >= 13*60+45 ){
                                                    count += 0.5;
                                                }
                                                if(min4>16*60+45&&min4<17*60+15){
//                                                    earlyTime +=17*60+15-min4;
                                                }else if(min4 <= 16*60+45 ){
                                                    count += 0.5;
                                                }
                                            }
                                        }
                                        curdateList.remove(curdateList.get(j));
                                        m = j - 1;
                                        break;
                                    }

                                }
                            }
                            for (String saturdayTime : saturdayList) {
                                if (saturdayTime.equals(key3)) {
//                                    computeSaturdayLateAndEarlyTime(finalTimeList, count, lateTime, earlyTime);
                                     if(finalTimeList.size()<=1){
                                        count +=0.5;
                                    }else if(finalTimeList.size()==2){
                                        String time1=finalTimeList.get(0);
                                        String time2=finalTimeList.get(1);
                                        int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                                        int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                                        int result1=time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60?1:0;
                                        if(result1==1){
                                            if(min1>=9*60||min2<=11*60+15){
                                                count +=0.5;
                                            }else{
                                                if(min1>8*60+30&&min1<9*60){
                                                    lateTime +=min1 - 8 * 60 - 30;
                                                }
                                                if(min2>11*60+15&&min2<11*60+45){
                                                    earlyTime +=11*60 + 45 - min2;
                                                }
                                            }
                                        }
                                    }
                                    saturdayList.remove(saturdayTime);
                                    break;
                                }
                            }
                        }
                            Double sumDays=0.0;
                            Double hour1=getLeaveTime(9,month,workCode);//上月底至本月初的请假数据
                            sumDays +=hour1/7.5;
                            Double hour2=getLeaveTime1(9,month,workCode);//本月底至下月初的请假数据
                            sumDays +=hour2/7.5;
                            count +=sumDays*0.5;
                            countAll = count +curdateList.size()+saturdayList.size()*0.5;
                            DecimalFormat decimalFormat=new DecimalFormat("0.0");
                            String ncountAll=decimalFormat.format(countAll);
                            out.println("<td align='center'>" + lateTime + "</td>");//迟到分钟数
                            out.println("<td align='center'>" + earlyTime + "</td>");//早退分钟数
                            out.println("<td align='center'>" + ncountAll + "</td>");//旷工天数
                            Double cnt10=0.00;
                            //请假数据获取 获取当月的请假数据 获取上月底至本月初的请假数据 获取本月底至下月初的请假数据
                            for (Integer num1 : typeList) {
                                //获取当月的请假数据
                                String leaveSql = "select case when sum(days) is null then 0.00 else sum(days) end as 总天数 from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') and " +
                                        " type=" + num1 + " and start_date like '%" + month + "%' and end_date like '%" + month + "%' ";
                                RecordSet rs13 = new RecordSet();
                                rs13.executeSql(leaveSql);
                                Double cnt7 = 0.0;
                                rs13.next();
                                cnt7 = rs13.getDouble(1);
                                cnt7 +=getLeaveTime(num1,month,workCode);
                                cnt7 +=getLeaveTime1(num1,month,workCode);
                                if(num1==8){
                                    cnt10=cnt7*7.25;
                                }
                                out.println("<td align='center'>" + cnt7 + "</td>");
                            }
                            //加点工时
                            String OvertimebyHourSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                    "WHERE WORK_DATE LIKE '%" + month + "%' AND userid=(select id from hrmresource where workcode like '%" + workCode + "%') AND " +
                                    "(OVERTIME_TYPE IN (0,2) or (OVERTIME_TYPE in (3) and break_off=1 and WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where week in(1,2,3,4,5)))) ";
                            RecordSet rs15 = new RecordSet();
                            rs15.executeSql(OvertimebyHourSql);
                            rs15.next();
                            Double cnt8 = rs15.getDouble(1);
                            DecimalFormat decimalFormat1=new DecimalFormat("0.00");
                            String newcnt8=decimalFormat1.format(cnt8);
                            out.println("<td align='center'>" + newcnt8 + "</td>");//加点工时
                            //加班工时
                            String addedHoursSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                    "WHERE WORK_DATE LIKE '%" + month + "%' AND userid=(select id from hrmresource where workcode like '%" + workCode + "%') and " +
                                    "WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where week in(6,7)) and break_off=1 and OVERTIME_TYPE in (1,3) ";
                            RecordSet rs16 = new RecordSet();
                            rs16.executeSql(addedHoursSql);
                            rs16.next();
                            Double cnt9 = rs16.getDouble(1);
                            String newcnt9=decimalFormat1.format(cnt9);
                            out.println("<td align='center'>" + newcnt9 + "</td>");//加班工时
                            //已用调休工时
                            String newcnt10=decimalFormat1.format(cnt10);
                            out.println("<td align='center'>" + newcnt10 + "</td>");//调休工时
                            //异常流程次数
                            String abnormalTimeSql = "select case when count(*) is null then 0 else count(*) end  from UF_ABNORMALSIGN where abnormal_date like '%" + month + "%' and userid=(select id from hrmresource where workcode like '%" + workCode + "%') ";
                            RecordSet rs9 = new RecordSet();
                            rs9.executeSql(abnormalTimeSql);
                            rs9.next();
                            int cnt5 = rs9.getInt(1);
                            out.println("<td align='center'>" + cnt5 + "</td>");//异常流程次数
                            //剩余调休时间
                            String spareLeaveSql = "select case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end from uf_TimePoolB where userid=(select id from hrmresource where workcode like '%" + workCode + "%') and iseffective=0 and workdate like '%" + month + "%' ";
                            RecordSet rs10 = new RecordSet();
                            rs10.executeSql(spareLeaveSql);
                            rs10.next();
                            Double cnt6 = rs10.getDouble(1);
                            out.println("<td align='center'>" + cnt6 + "</td>");//剩余调休工时
                            //获取年假数据 总时长 已用时长 剩余时长
                            String annualInfoSql = "select total_hours,used_hours,DECODE(total_hours-used_hours,null,0,total_hours-used_hours) spareHours from UF_HODO_ANNUAL_INFO where userid=(select id from hrmresource where workcode like '%" + workCode + "%')  ";
                            RecordSet rs11 = new RecordSet();
                            rs11.executeSql(annualInfoSql);
                            Double totalHours = 0.0;
                            Double usedHours = 0.0;
                            Double spareHours = 0.0;
                            if (rs11 != null && rs11.next()) {
                                totalHours = rs11.getDouble(1);
                                usedHours = rs11.getDouble(2);
                                spareHours = rs11.getDouble(3);
                            } else {
                                totalHours = 0.0;
                                usedHours = 0.0;
                                spareHours = 0.0;
                            }
                            out.println("<td align='center'>" + totalHours + "</td>");//总共年假
                            out.println("<td align='center'>" + usedHours + "</td>");//已用年假
                            out.println("<td align='center'>" + spareHours + "</td>");//可用年假
                            out.println("</tr>");
                        }
                    }
                    }else{
                        //为空则输出无查询结果
                        out.println("<tr>");
                        out.println("<td style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center'>无查询结果，请确认查询报表条件</td>");
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
                    String subcompanyname = rs.getString("subcompanyname");
                    //机构名称
                    String departmentname = rs.getString("departmentname");
                    //人员编号
                    String workCode = rs.getString("workCode");
                    //姓名
                    String lastname = rs.getString("lastname");
                    //考勤日期
                    String signDate = rs.getString("signDate");
                    //考勤时间
                    String signTime = rs.getString("signTime");
                    //考勤类型
                    String signType = rs.getString("signType");
                    //应出勤
                    String days = rs.getString("days");
                    //员工id
                    String id = rs.getString("id");
                    //法定节假日
                    String holiday = rs.getString("holiday");
                    if(!signTime.isEmpty() && signTime!=null && !signType.isEmpty() && signType!=null){
                    signTime  = signTime + ":" + signType;
                    }
                    //定义集合的key值
                    String key = subcompanyname+","+departmentname+","+workCode+","+lastname+","+id+","+days+","+holiday;

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

                <!--改变出差时的打卡时间 -->
                <%!
                    public static void changeBusinessTripTime(Map<String,List<String>> value,String checkMinDate,String checkMaxDate,String id,String month){
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    List<String> businesstripTimeList1 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间 下午签到时间 下午签退时间
                    businesstripTimeList1.add("08:30:00:1");
                    businesstripTimeList1.add("11:45:00:2");
                    businesstripTimeList1.add("13:00:00:1");
                    businesstripTimeList1.add("17:15:00:2");
                    List<String> businesstripTimeList2 = new ArrayList<String>();//全天标准打卡数据 上午签退时间 下午签到时间 下午签退时间
                    businesstripTimeList2.add("11:45:00:2");
                    businesstripTimeList2.add("13:00:00:1");
                    businesstripTimeList2.add("17:15:00:2");
                    List<String> businesstripTimeList3 = new ArrayList<String>();//全天标准打卡数据 下午签到时间 下午签退时间
                    businesstripTimeList3.add("13:00:00:1");
                    businesstripTimeList3.add("17:15:00:2");
                    List<String> businesstripTimeList4 = new ArrayList<String>();//全天标准打卡数据 下午签退时间
                    businesstripTimeList4.add("17:15:00:2");
                    List<String> businesstripTimeList5 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间 下午签到时间
                    businesstripTimeList5.add("08:30:00:1");
                    businesstripTimeList5.add("11:45:00:2");
                    businesstripTimeList5.add("13:00:00:1");
                    List<String> businesstripTimeList6 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间
                    businesstripTimeList6.add("08:30:00:1");
                    businesstripTimeList6.add("11:45:00:2");
                    List<String> businesstripTimeList7 = new ArrayList<String>();//全天标准打卡数据 上午签到时间
                    businesstripTimeList7.add("08:30:00:1");
                    String sql1 = "SELECT start_date,start_time,end_date,end_time from uf_BusinessTrip WHERE userid = "+id+" and (start_date like '%"+month+"%' or end_date like '%"+month+"%') ORDER BY start_date";
                    RecordSet rs1 = new RecordSet();
                    rs1.executeSql(sql1);
                    while(rs1.next()) {
                    List<String> dateList = new ArrayList<String>();
                    List<String> finalDateList = new ArrayList<String>();
                    //出差开始日期
                    String startDate = rs1.getString("start_date");
                    //出差结束日期
                    String endDate = rs1.getString("end_date");
                    //出差开始时间
                    String startTime = rs1.getString("start_time");
                    //出差结束时间
                    String endTime = rs1.getString("end_time");
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
                        if(Integer.parseInt(businesstripDate.split("-")[1])==Integer.parseInt(month.split("-")[1])){
                            finalDateList.add(dateList.get(i));
                        }
                    }
                    for (int i = 0; i < finalDateList.size(); i++) {
                        String businesstripDate = finalDateList.get(i);
                        //根据用户id和日期查询当天是否有业务考勤打卡记录
                        String attendanceSql1 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = "+id+" and ms.operate_date = '"+businesstripDate+"'";
                        RecordSet rs2 = new RecordSet();
                        rs2.executeSql(attendanceSql1);
                        rs2.next();
                        //是否有业务考勤记录
                        int isAttendance1 = rs2.getInt(1);
                        if(isAttendance1>=1){
                            value.put(businesstripDate,businesstripTimeList1);
                        }
                    }
                    //出差开始日期和出差结束日期不是同一天
                    if(!startDate.equals(endDate)){
                    //2.处理出差开始当天的考勤打卡时间
                    //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                    String attendanceSql2 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = "+id+" and ms.operate_date = '"+startDate+"'";
                    RecordSet rs3 = new RecordSet();
                    rs3.executeSql(attendanceSql2);
                    rs3.next();
                    int isAttendance2 = rs3.getInt(1);
                    //出差开始日期当天的打卡记录集合
                    List<String> businesstripStartDate = value.get(startDate);
                    if(sdf.parse(startDate).getTime() >= sdf.parse(checkMinDate).getTime()){
                        if(businesstripStartDate!=null){
                            for (int i = 0; i < businesstripStartDate.size(); i++) {
                                businesstripTimeList2.add(businesstripStartDate.get(i));
                                businesstripTimeList3.add(businesstripStartDate.get(i));
                                businesstripTimeList4.add(businesstripStartDate.get(i));
                            }
                        }
                        int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                        int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);
                        int startMinutes=startTimeForHours*60+startTimeForMinutes;//出差开始时间对应的分钟
                        /**
                         * 出差开始日期当天打卡记录且有当天业务考勤记录
                         * 出差开始时间 <8:30 将上午标准签到签退时间、下午标准签到签退时间添加
                         * 出差开始时间 8:30--11：45 将上午签退、下午签到签退标准时间添加
                         * 出差开始时间 11:45-13:00 将下午签到签退标准时间添加
                         * 出差开始时间 13:00-17:15 将下午标准签退时间添加
                         * 2020/04/18 zcc
                         */
                        if(isAttendance2>=1){
                            if(startMinutes<=(8*60+30)){
                                value.put(startDate,businesstripTimeList1);
                            }else if(startMinutes<=(11*60+45)){
                                value.put(startDate,businesstripTimeList2);
                            }else if(startMinutes<=(13*60)){
                                value.put(startDate,businesstripTimeList3);
                            }else if(startMinutes<=(17*60+15)){
                                value.put(startDate,businesstripTimeList4);
                            }else{
                                if(businesstripStartDate!=null){
                                    value.put(startDate,businesstripStartDate);
                                }else{
                                    value.put(startDate,businesstripTimeList1);
                                }
                            }
                        }
                    }
                    //3.处理出差结束当天的考勤打卡时间
                    //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                    String attendanceSql3 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = "+id+" and ms.operate_date = '"+startDate+"'";
                    RecordSet rs4 = new RecordSet();
                    rs4.executeSql(attendanceSql3);
                    rs4.next();
                    int isAttendance3 = rs4.getInt(1);
                    List<String> businesstripEndDate = value.get(endDate);//出差结束日期当天的打卡记录集合
                    if(sdf.parse(endDate).getTime() <= sdf.parse(checkMaxDate).getTime()){
                        if(businesstripEndDate!=null){
                            for (int i = 0; i < businesstripEndDate.size(); i++) {
                                //出差结束日期有打卡记录 根据打卡记录的条数来进行判断 将标准时间添加到集合中处理
                                businesstripTimeList5.add(businesstripEndDate.get(i));
                                businesstripTimeList6.add(businesstripEndDate.get(i));
                                businesstripTimeList7.add(businesstripEndDate.get(i));
                            }
                        }
                        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);
                        int endMinutes=endTimeForHours*60+endTimeForMinutes;//结束时间对应的分钟数
                        /**
                         * 出差结束日期当天打卡记录且有当天业务考勤记录
                         * 出差开始日期当天打卡记录且有当天业务考勤记录
                         * 出差开始时间 <=8:30 将上午标准签到签退时间、下午标准签到签退时间添加
                         * 出差开始时间 8:30--11：45 将上午签退、下午签到签退标准时间添加
                         * 出差开始时间 11:45-13:00 将下午签到签退标准时间添加
                         * 出差开始时间 13:00-17:15 将下午标准签退时间添加
                         * 出差结束时间 8:30--11：45 将上午标准签到时间添加
                         * 出差结束时间 11:45-13:00 将上午标准签到签退时间添加
                         * 出差结束时间 13:00-17:15 将上午标准签到签退时间、下午标准签到时间添加
                         * 出差结束时间 >17:15 将上午
                         * 出差天数为1天 开始《8：30 结束11：45-13:15 取上午签到、签退时间
                         * 2020/04/18 zcc
                         */
                        if(isAttendance3>=1){
                            if(endMinutes<(11*60+45)&&endMinutes>=(8*60+30)){
                                 value.put(endDate,businesstripTimeList7);
                            }else if(endMinutes<(13*60)){
                                 value.put(endDate,businesstripTimeList6);
                            }else if(endMinutes<(17*60+15)){
                                 value.put(endDate,businesstripTimeList5);
                            }else if(endMinutes>=(17*60+15)){
                                 value.put(endDate,businesstripTimeList1);
                            }
                        }
                    }
                    }else{
                        //调用方法，处理当天的打卡时间
                        changeTodayTime(value,startTime,endTime,startDate);
                    }
                    }catch (Exception e){
                    e.printStackTrace();
                    }
                    }
                    }
                %>

                <!--改变外出时的打卡时间 -->
                <%!
                    public static void changeGoOutTime(Map<String,List<String>> value,String id,String month){
                        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                        String sql = "SELECT outdate,starttime,endtime from uf_goOut WHERE userid = "+id+" AND outdate like '%"+month+"%' ORDER BY outdate";
                        RecordSet rs = new RecordSet();
                        rs.executeSql(sql);
                        while(rs.next()) {
                            String outdate = rs.getString("outdate");//外出日期
                            String startTime = rs.getString("starttime"); //外出开始时间
                            String endTime = rs.getString("endtime"); //外出结束时间
                            //根据日期查询排版表
                            String attendanceSql2 = "select isattendance,week from uf_attendance where curdate = '"+outdate+"'";
                            RecordSet rs3 = new RecordSet();
                            rs3.executeSql(attendanceSql2);
                            rs3.next();
                            int isAttendance2 = rs3.getInt(1);
                            int week2 = rs3.getInt(2);
                            boolean result = (isAttendance2==1 && week2==7) || (isAttendance2==1 && week2==6);
                            if(!result&&week2<=5){
                                //调用方法，处理当天的打卡时间
                                changeTodayTime(value,startTime,endTime,outdate);
                            }else if(!result&&week2==6){
                                changeSaturdayTime(value,startTime,endTime,outdate);
                            }
                        }
                    }
                %>

                <!--改变异常考勤时的打卡时间 -->
                <%!
                    public static void changeAbnormalSignTime(Map<String,List<String>> value,String id,String month){
                        String sql = "SELECT abnormal_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from UF_ABNORMALSIGN  WHERE abnormal_date like '%"+month+"%' AND userid = "+id+"";
                        RecordSet rs = new RecordSet();
                        rs.executeSql(sql);
                        while(rs.next()){
                            String abnormalDate = rs.getString("abnormal_date");//考勤异常日期
                            String morningSignIn = rs.getString("morning_sign_in"); //上午签到考勤异常
                            String morningSignBack = rs.getString("morning_sign_back"); //上午签退考勤异常
                            String afternoonSignIn = rs.getString("afternoon_sign_in"); //下午签到考勤异常
                            String afternoonSignBack = rs.getString("afternoon_sign_back"); //下午签退考勤异常
                            List<String> abnormalSignDate = value.get(abnormalDate); //获取考勤异常当天的打卡时间集合
                            List<String> abnormalSignTempDate = new ArrayList<String>();
                            /**
                             * 异常类型 上午签到 添加上午签到标准时间 上午签退 添加上午签退标准时间 下午签到 添加下午签到标准时间 下午签退 添加下午签退标准时间
                             */
                            if(morningSignIn.equals("1")){
                                if(abnormalSignDate!=null){
                                    value.put(abnormalDate,abnormalSignDate);
                                }else{
                                    abnormalSignTempDate.add("08:30:00:1");
                                    value.put(abnormalDate,abnormalSignTempDate);
                                }
                            }
                            if(morningSignBack.equals("1")){
                                if(abnormalSignDate!=null){
                                    value.put(abnormalDate,abnormalSignDate);
                                }else{
                                    abnormalSignTempDate.add("11:45:00:2");
                                    value.put(abnormalDate,abnormalSignTempDate);
                                }
                            }
                            if(afternoonSignIn.equals("1")){
                                if(abnormalSignDate!=null){
                                    value.put(abnormalDate,abnormalSignDate);
                                }else{
                                    abnormalSignTempDate.add("13:00:00:1");
                                    value.put(abnormalDate,abnormalSignTempDate);
                                }
                            }
                            if(afternoonSignBack.equals("1")){
                                if(abnormalSignDate!=null){
                                    value.put(abnormalDate,abnormalSignDate);
                                }else{
                                    abnormalSignTempDate.add("17:15:00:2");
                                    value.put(abnormalDate,abnormalSignTempDate);
                                }
                            }
                        }
                    }
                %>

                <!--改变请假(调休、年假)的打卡时间 -->
                <%!
                    public static void changeLeaveTime(Map<String,List<String>> value,String checkMinDate,String checkMaxDate,String id,String month,int type){
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    //全天标准打卡数据
                    List<String> timeList1 = new ArrayList<String>();
                    timeList1.add("08:30:00:1");
                    timeList1.add("11:45:00:2");
                    timeList1.add("13:00:00:1");
                    timeList1.add("17:15:00:2");
                    //上午下班、下午上班、下午下班标准打卡数据
                    List<String> timeList2 = new ArrayList<String>();
                    timeList2.add("11:45:00:2");
                    timeList2.add("13:00:00:1");
                    timeList2.add("17:15:00:2");
                    //下午上班、下午下班标准打卡数据
                    List<String> timeList3 = new ArrayList<String>();
                    timeList3.add("13:00:00:1");
                    timeList3.add("17:15:00:2");
                    //下午下班标准打卡数据
                    List<String> timeList4 = new ArrayList<String>();
                    timeList4.add("17:15:00:2");
                    //上午上班、上午下班、下午上班卡标准打卡数据
                    List<String> timeList5 = new ArrayList<String>();
                    timeList5.add("08:30:00:1");
                    timeList5.add("11:45:00:2");
                    timeList5.add("13:00:00:1");
                    //上午上班、上午下班标准打卡数据
                    List<String> timeList6 = new ArrayList<String>();
                    timeList6.add("08:30:00:1");
                    timeList6.add("11:45:00:2");
                    //上午上班标准打卡数据
                    List<String> timeList7 = new ArrayList<String>();
                    timeList7.add("08:30:00:1");

                    String sql = "SELECT start_date,start_time,end_date,end_time from uf_askForLeave WHERE type = "+type+" AND userid = "+id+" " +
                            "and (start_date like '%"+month+"%' or end_date like '%"+month+"%') ORDER BY start_date";
                    RecordSet rs = new RecordSet();
                    rs.executeSql(sql);
                    while(rs.next()){
                    List<String> dateList = new ArrayList<String>();
                    List<String> finalDateList = new ArrayList<String>();
                    //调休(年假)请假开始日期
                    String startDate = rs.getString("start_date");
                    //调休(年假)请假结束日期
                    String endDate = rs.getString("end_date");
                    //调休(年假)请假开始时间
                    String startTime = rs.getString("start_time");
                    //调休(年假)请假结束时间
                    String endTime = rs.getString("end_time");
                    //1.处理调休请假期间的打卡数据
                    Calendar c1 = Calendar.getInstance();
                    try {
                    c1.setTime(sdf.parse(startDate));
                    long time = sdf.parse(endDate).getTime();
                    for (long d = c1.getTimeInMillis(); d <= time; d = getTimeMillis(c1)) {
                        dateList.add(sdf.format(d));
                    }
                    for (int i = 1; i < dateList.size() - 1; i++) {
                        String valueDate = dateList.get(i);
                        if(Integer.parseInt(valueDate.split("-")[1])==Integer.parseInt(month.split("-")[1])){
                            finalDateList.add(dateList.get(i));
                        }
                    }
                    for (int i = 0; i < finalDateList.size(); i++) {
                        String valueDate = finalDateList.get(i);
                        //根据日期查询排版表
                        String attendanceSql = "select isattendance,week from uf_attendance where curdate = '"+valueDate+"'";
                        RecordSet rs2 = new RecordSet();
                        rs2.executeSql(attendanceSql);
                        rs2.next();
                        //获取今天是否是工作日
                        int isAttendance = rs2.getInt(1);
                        //获取今天为周几
                        int week = rs2.getInt(2);
                        //非工作日周日、非工作日周六
                        boolean result = (isAttendance==1 && week==7) || (isAttendance==1 && week==6);
                        if(!result){
                            value.put(valueDate,timeList1);
                        }
                    }
                    //请假开始日期和请假结束日期不为同一天
                    if((!startDate.equals(endDate))){
                    //2.处理调休(年假)请假开始当天的考勤打卡时间
                    //根据日期查询排版表
                    String weekResult=getAttendanceAndWeek(endDate);
                    int isAttendance2=Integer.parseInt(weekResult.split(",")[0]);
                    int week2=Integer.parseInt(weekResult.split(",")[1]);
                    /**
                     *  调休(年假)请假开始日期当天的打卡记录集合
                        * 请假开始日期
                        * 请假开始时间 <=8:30 将上午标准签到签退时间、下午标准签到签退时间添加
                        * 请假开始时间 8:30--11：45 将上午签退、下午签到签退标准时间添加
                        * 请假开始时间 11:45-13:00 将下午签到签退标准时间添加
                        * 请假开始时间 13:00-17:15 将下午标准签退时间添加
                        *请假结束日期
                        * 请假结束时间 8:30--11：45 将上午标准签到时间添加
                        * 请假结束时间 11:45-13:00 将上午标准签到签退时间添加
                        * 请假结束时间 13:00-17:15 将上午标准签到签退时间、下午标准签到时间添加
                        * 请假结束时间 >17:15 将上午标准签到签退时间、下午标准签到、签退时间添加
                        * 请假天数为1天 开始<8：30 结束11：45-13:15 取上午签到、签退时间
                     */
                    List<String> valueStartDate = value.get(startDate);
                    if(sdf.parse(startDate).getTime() >= sdf.parse(checkMinDate).getTime()){
                        if(valueStartDate!=null){
                            for (int i = 0; i < valueStartDate.size(); i++) {
                                timeList2.add(valueStartDate.get(i));
                                timeList3.add(valueStartDate.get(i));
                                timeList4.add(valueStartDate.get(i));
                            }
                        }
                        int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                        int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);
                        //非工作日周日、非工作日周六
                        boolean result = (isAttendance2==1 && week2==7) || (isAttendance2==1 && week2==6);
                        //调休(年假)请假开始日期当天打卡记录
                        if(!result){
                            if((startTimeForHours*60+startTimeForMinutes)<=(8*60+30)){
                                value.put(startDate,timeList1);
                            }else if((startTimeForHours*60+startTimeForMinutes)<=(11*60+45)){
                                value.put(startDate,timeList2);
                            }else if((startTimeForHours*60+startTimeForMinutes)<=(13*60)){
                                value.put(startDate,timeList3);
                            }else if((startTimeForHours*60+startTimeForMinutes)<=(17*60+15)){
                                value.put(startDate,timeList4);
                            }else{
                                if(valueStartDate!=null){
                                    value.put(startDate,valueStartDate);
                                }else{
                                    value.put(startDate,timeList1);
                                }
                            }
                        }
                    }
                    //3.处理调休(年假)请假结束当天的考勤打卡时间
                    String weekResult1=getAttendanceAndWeek(endDate);
                    int isAttendance3=Integer.parseInt(weekResult1.split(",")[0]);
                    int week3=Integer.parseInt(weekResult1.split(",")[1]);
                    //调休(年假)请假结束日期当天的打卡记录集合
                    List<String> valueEndDate = value.get(endDate);
                    if(sdf.parse(endDate).getTime() <= sdf.parse(checkMaxDate).getTime()){
                        if(valueEndDate!=null){
                            for (int i = 0; i < valueEndDate.size(); i++) {
                            timeList5.add(valueEndDate.get(i));
                            timeList6.add(valueEndDate.get(i));
                            timeList7.add(valueEndDate.get(i));
                            }
                        }
                        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);
                        //非工作日周日、非工作日周六
                        boolean result = (isAttendance3==1 && week3==7) || (isAttendance3==1 && week3==6);
                        //调休(年假)请假结束日期当天打卡记录
                        if(!result){
                            if((endTimeForHours*60+endTimeForMinutes)<(8*60+30)){
                                if(valueEndDate!=null){
                                value.put(endDate,valueEndDate);
                                }
                            }else if((endTimeForHours*60+endTimeForMinutes)<(11*60+45)){
                                value.put(endDate,timeList7);
                            }else if((endTimeForHours*60+endTimeForMinutes)<(13*60)){
                                value.put(endDate,timeList6);
                            }else if((endTimeForHours*60+endTimeForMinutes)<(17*60+15)){
                                value.put(endDate,timeList5);
                            }else{
                                value.put(endDate,timeList1);
                            }
                        }
                    }
                    }else{
                        //请假开始日期和请假结束日期为同一天
                        //根据日期查询排版表
                        String attendanceSql4 = "select isattendance,week from uf_attendance where curdate = '"+endDate+"'";
                        RecordSet rs5 = new RecordSet();
                        rs5.executeSql(attendanceSql4);
                        rs5.next();
                        int isAttendance4 = rs5.getInt(1);
                        int week4 = rs5.getInt(2);
                        //非工作日周日、非工作日周六
                        boolean result = (isAttendance4==1 && week4==7) || (isAttendance4==1 && week4==6);
                        //调休(年假)请假结束日期当天打卡记录
                        if(!result && week4<=5){
                            //调用方法，处理当天的打卡时间
                            changeTodayTime(value,startTime,endTime,startDate);
                        }else if(!result && week4==6){
                            changeSaturdayTime(value,startTime,endTime,startDate);
                        }
                    }
                    }catch (Exception e){
                        e.printStackTrace();
                    }
                    }
                    }
                %>
                <!-- 处理当天(1-5)时间 -->
                <%!
                    public static void changeTodayTime(Map<String,List<String>> value,String startTime,String endTime,String outdate){
                        //处理外出当天的考勤打卡时间
                        //外出当天的打卡记录集合
                        List<String> gooutStartDate = value.get(outdate);

                        List<String> gooutStartTempDate = new ArrayList<String>();
                        int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                        int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);
                        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

                        //前提（结束时间一定大于开始时间）
                        //1.外出开始时间小于等于8:30,外出结束时间小于等于8:30
                        boolean result1 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)<=(8*60+30);

                        //2.外出开始时间小于等于8:30,外出结束时间小于11:45
                        boolean result2 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)<(11*60+45);

                        //3.外出开始时间小于等于8:30,外出时间小于13:15
                        boolean result3 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)<(13*60+15);

                        //4.外出开始时间小于等于8:30,外出时间小于17:15
                        boolean result4 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)<(17*60+15);

                        //5.外出开始时间小于等于8:30,外出时间大于等于17:15
                        boolean result5 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)>=(17*60+15);

                        //6.外出开始时间小于11:45,外出结束时间小于11:45
                        boolean result6 = (startTimeForHours*60+startTimeForMinutes)>(8*60+30) && (startTimeForHours*60+startTimeForMinutes)<(11*60+45) && (endTimeForHours*60+endTimeForMinutes)<(11*60+45);

                        //7.外出开始时间小于11:45,外出结束时间小于13:15
                        boolean result7 = (startTimeForHours*60+startTimeForMinutes)>(8*60+30) && (startTimeForHours*60+startTimeForMinutes)<(11*60+45) && (endTimeForHours*60+endTimeForMinutes)<(13*60+15);

                        //8.外出开始时间小于11:45,外出结束时间小于17:15
                        boolean result8 = (startTimeForHours*60+startTimeForMinutes)>(8*60+30) && (startTimeForHours*60+startTimeForMinutes)<(11*60+45) && (endTimeForHours*60+endTimeForMinutes)<(17*60+15);

                        //9.外出开始时间小于11:45,外出结束时间大于等于17:15
                        boolean result9 = (startTimeForHours*60+startTimeForMinutes)>(8*60+30) && (startTimeForHours*60+startTimeForMinutes)<(11*60+45) && (endTimeForHours*60+endTimeForMinutes)>=(17*60+15);

                        //10.外出开始时间小于13:15,外出结束时间小于13:15
                        boolean result10 = (startTimeForHours*60+startTimeForMinutes)>=(11*60+45) && (startTimeForHours*60+startTimeForMinutes)<(13*60+15) && (endTimeForHours*60+endTimeForMinutes)<(13*60+15);

                        //11.外出开始时间小于13:15,外出结束时间小于17:15
                        boolean result11 = (startTimeForHours*60+startTimeForMinutes)>=(11*60+45) && (startTimeForHours*60+startTimeForMinutes)<(13*60+15) && (endTimeForHours*60+endTimeForMinutes)<(17*60+15);

                        //12.外出开始时间小于13:15,外出结束时间大于等于17:15
                        boolean result12 = (startTimeForHours*60+startTimeForMinutes)>=(11*60+45) && (startTimeForHours*60+startTimeForMinutes)<(13*60+15) && (endTimeForHours*60+endTimeForMinutes)>=(17*60+15);

                        //13.外出开始时间小于17:15,外出结束时间小于17:15
                        boolean result13 = (startTimeForHours*60+startTimeForMinutes)>=(13*60+15) && (startTimeForHours*60+startTimeForMinutes)<(17*60+15) && (endTimeForHours*60+endTimeForMinutes)<(17*60+15);

                        //14.外出开始时间小于17:15,外出结束时间大于等于17:15
                        boolean result14 = (startTimeForHours*60+startTimeForMinutes)>=(13*60+15) && (startTimeForHours*60+startTimeForMinutes)<(17*60+15) && (endTimeForHours*60+endTimeForMinutes)>=(17*60+15);

                        //15.外出开始时间大于等于17:15
                        boolean result15 = (startTimeForHours*60+startTimeForMinutes)>=(17*60+15);

                        //外出当天打卡记录
                        if(result1 || result6 || result10 || result13 || result15){
                            if(gooutStartDate!=null){
                                value.put(outdate,gooutStartDate);
                            }
                        }else if(result2){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result3){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                gooutStartDate.add("11:45:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                gooutStartTempDate.add("11:45:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result4){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                gooutStartDate.add("11:45:00:2");
                                gooutStartDate.add("13:00:00:1");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                gooutStartTempDate.add("11:45:00:2");
                                gooutStartTempDate.add("13:00:00:1");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result5){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                gooutStartDate.add("11:45:00:2");
                                gooutStartDate.add("13:00:00:1");
                                gooutStartDate.add("17:15:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                gooutStartTempDate.add("11:45:00:2");
                                gooutStartTempDate.add("13:00:00:1");
                                gooutStartTempDate.add("17:15:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result7){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("11:45:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("11:45:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result8){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("11:45:00:2");
                                gooutStartDate.add("13:00:00:1");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("11:45:00:2");
                                gooutStartTempDate.add("13:00:00:1");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result9){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("11:45:00:2");
                                gooutStartDate.add("13:00:00:1");
                                gooutStartDate.add("17:15:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("11:45:00:2");
                                gooutStartTempDate.add("13:00:00:1");
                                gooutStartTempDate.add("17:15:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result11){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("13:00:00:1");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("13:00:00:1");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result12){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("13:00:00:1");
                                gooutStartDate.add("17:15:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("13:00:00:1");
                                gooutStartTempDate.add("17:15:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result14){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("17:15:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("17:15:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }
                    }
                %>
                <!-- 处理当天(周六)时间 -->
                <%!
                    public static void changeSaturdayTime(Map<String,List<String>> value,String startTime,String endTime,String outdate){
                        //处理外出当天的考勤打卡时间
                        //外出当天的打卡记录集合
                        List<String> gooutStartDate = value.get(outdate);
                        List<String> gooutStartTempDate = new ArrayList<String>();
                        int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                        int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);
                        int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                        int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

                        //1.外出开始时间小于等于8:30,外出结束时间小于11:45
                        boolean result1 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)<(11*60+45);
                        //2.外出开始时间小于等于8:30,外出时间大于等于11:15
                        boolean result2 = (startTimeForHours*60+startTimeForMinutes)<=(8*60+30) && (endTimeForHours*60+endTimeForMinutes)>=(11*60+45);
                        //3.外出开始时间小于11:45,外出结束时间大于等于11:45
                        boolean result3 = (startTimeForHours*60+startTimeForMinutes)>(8*60+30) && (startTimeForHours*60+startTimeForMinutes)<(11*60+45) && (endTimeForHours*60+endTimeForMinutes)>=(11*60+45);

                        //外出当天打卡记录
                        if(result1){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result2){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("08:30:00:1");
                                gooutStartDate.add("11:45:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("08:30:00:1");
                                gooutStartTempDate.add("11:45:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }else if(result3){
                            if(gooutStartDate!=null){
                                gooutStartDate.add("11:45:00:2");
                                value.put(outdate,gooutStartDate);
                            }else{
                                gooutStartTempDate.add("11:45:00:2");
                                value.put(outdate,gooutStartTempDate);
                            }
                        }
                    }
                %>
                <!--获取日期对应的应出勤状态及星期-->
                <%!
                        public static String getAttendanceAndWeek(String endDate){
                            String attendanceSql3 = "select isattendance,week from uf_attendance where curdate = '"+endDate+"'";
                            RecordSet rs4 = new RecordSet();
                            rs4.executeSql(attendanceSql3);
                            rs4.next();
                            int isAttendance3 = rs4.getInt(1);
                            int week3 = rs4.getInt(2);
                            String result= String.valueOf(isAttendance3)+","+String.valueOf(week3);
                            return result;
                        }
                %>
                <!--计算周一至周五迟到早退旷工时间-->
                <%!
                public static void computeDailyLateAndEarlyTime(List<String> finalTimeList,Double count,Double lateTime,Double earlyTime){
                    /**
                     *迟到早退旷工计算规则
                     * 打卡记录为 0或1次打卡记录 算旷工一天
                     * 打卡记录为 2次打卡记录 上午签到
                     */
                    int collectionSize=finalTimeList.size();//打卡时间集合大小
                    //判断是否有加班时间 如果有下午加班时间 设置新的集合长度
                    for(String time:finalTimeList){
                        int min=Integer.parseInt(time.substring(0,2))*60+Integer.parseInt(time.substring(3,5));
                        int index=0;
                        if(time.endsWith("2")&&min>12*60){
                            index++;
                        }
                        if(index>1){
                            collectionSize =collectionSize-index+1;
                        }
                    }
                    if (collectionSize <= 1) {
                        count++;
                    } else if (collectionSize == 2) {
                        /**
                         * 两次记录
                         * 上午签到 上午签退 result1
                         * 上午签到 下午签到 result2
                         * 上午签到 下午签退 result3
                         * 上午签退 下午签到 result4
                         * 上午签退 下午签退 result5
                         * 下午签到 下午签退 result6
                         */
                        String time1=finalTimeList.get(0);
                        String time2=finalTimeList.get(1);
                        int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                        int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                        int result1=time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60?1:0;
                        int result2=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60)||(time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2>12*60)||
                                (time1.endsWith("2")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60)||(time1.endsWith("2")&&min1<12*60&&time2.endsWith("2")&&min2>12*60))?1:0;
                        int result3=time1.endsWith("1")&&min1>=12*60&&time2.endsWith("2")&&min2>=12*60?1:0;
                        if(result1==1){
                            if(min1>=9*60||min2<=11*60+15){
                                count++;
                            }else{
                                if(min1>8*60+30&&min1<9*60){
                                    lateTime +=min1 - 8 * 60 - 30;
                                }
                                if(min2>11*60+15&&min2<11*60+45){
                                    earlyTime +=11*60 + 45 - min2;
                                }
                                count +=0.5;
                            }
                        }
                        if(result2==1){
                            count++;
                        }
                        if(result3==1){
                            if(min1>=13*60+45||min2<=16*60+45){
                                count++;
                            }else{
                                if(min1>13*60+15&&min1<13*60+45){
                                    lateTime +=min1-13*60-15;
                                }
                                if(min2>16*60+45&&min2<17*60+15){
                                    earlyTime +=17*60+15-min2;
                                }
                                count +=0.5;
                            }
                        }
                    } else if (collectionSize == 3) {
                        /**
                         * 三次打卡记录
                         * 上午签到 上午签退 下午签到 result1
                         * 上午签到 上午签退 下午签退 result2
                         * 上午签到 下午签到 下午签退 result3
                         * 上午签退 下午签到 下午签退 result4
                         */
                        String time1=finalTimeList.get(0);
                        String time2=finalTimeList.get(1);
                        String time3=finalTimeList.get(2);
                        int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                        int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                        int min3 = Integer.parseInt(time3.substring(0, 2)) * 60 + Integer.parseInt(time3.substring(3, 5));
                        int result1=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60&&time1.endsWith("1")&&min3>=12*60)||
                                (time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60&&time1.endsWith("2")&&min3>=12*60))?1:0;
                        int result2=((time1.endsWith("1")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60&&time1.endsWith("2")&&min3>=12*60)||
                                (time1.endsWith("2")&&min1<12*60&&time2.endsWith("1")&&min2>=12*60&&time1.endsWith("2")&&min3>=12*60))?1:0;
                        if(result1==1){
                            if(min1>=9*60||min2<=11*60+15){
                                count++;
                            }else{
                                if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                                    lateTime += min1 - 8 * 60 - 30;
                                }
                                if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                                    earlyTime += 11 * 60 + 45 - min2;
                                }
                                count += 0.5;
                            }
                        }
                        if(result2==1){
                            if(min2>=13*60+45||min3<=16*60+45){
                                count++;
                            }else{
                                if(min2>13*60+15&&min2<13*60+45){
                                    lateTime +=min2-13*60-15;
                                }
                                if(min3>16*60+45&&min3<17*60+15){
                                    earlyTime +=17*60+15-min3;
                                }
                                count +=0.5;
                            }
                        }
                    } else if (collectionSize == 4) {
                        String time1=finalTimeList.get(0);
                        String time2=finalTimeList.get(1);
                        String time3=finalTimeList.get(2);
                        String time4=finalTimeList.get(3);
                        int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));//上午签到时间对应的分钟数
                        int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));//上午签退时间对应的分钟数
                        int min3 = Integer.parseInt(time3.substring(0, 2)) * 60 + Integer.parseInt(time3.substring(3, 5));//下午签到时间对应的分钟数
                        int min4 = Integer.parseInt(time4.substring(0, 2)) * 60 + Integer.parseInt(time4.substring(3, 5));//下午签退时间对应的分钟数
                        if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                            lateTime += min1 - 8 * 60 - 30;
                        }
                        if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                            earlyTime += 11 * 60 + 45 - min2;
                        }
                        if(min3>13*60+15&&min3<13*60+45){
                            lateTime +=min3-13*60-15;
                        }
                        if(min4>16*60+45&&min4<17*60+15){
                            earlyTime +=17*60+15-min4;
                        }
                        /**
                         * 打卡记录有3次及以上超过规定时间的半个小时
                         */
                        if((min1>=9*60&&min2<=11*60+15)||(min3>=13*60+45&&min4<=16*60+45)){
                            if((min1>=9*60||min2<=11*50+15)){
                                if(min3>13*60+15&&min3<13*60+45){
                                    lateTime +=min3-13*60-15;
                                }
                                if(min4>16*60+45&&min4<17*60+15){
                                    earlyTime +=17*60+15-min4;
                                }
                            }
                            if(min3>=13*60+45||min4<=16*60+45){
                                if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                                    lateTime += min1 - 8 * 60 - 30;
                                }
                                if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                                    earlyTime += 11 * 60 + 45 - min2;
                                }
                            }
                            count +=0.5;
                        }else if((min1>=9*60&&min3>=13*60+45)||(min1>=9*60&&min4<=16*60+45)||
                                (min2<=11*50+15&&min3>=13*60+45)||(min2<=11*60+15&&min4<=16*60+45)){
                            count++;
                        }else{
                            if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                                lateTime += min1 - 8 * 60 - 30;
                            }else if(min1 >= 9 * 60){
                                count +=0.5;
                            }
                            if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                                earlyTime += 11 * 60 + 45 - min2;
                            }else if(min2 <= 11 * 60 + 15 ){
                                count +=0.5;
                            }
                            if(min3>13*60+15&&min3<13*60+45){
                                lateTime +=min3-13*60-15;
                            }else if(min3 >= 13*60+45 ){
                                count += 0.5;
                            }
                            if(min4>16*60+45&&min4<17*60+15){
                                earlyTime +=17*60+15-min4;
                            }else if(min4 <= 16*60+45 ){
                                count += 0.5;
                            }
                        }
                    }
                }
        %>
                <!--计算周六迟到早退旷工时间-->
                <%!
                public static void computeSaturdayLateAndEarlyTime(List<String> finalTimeList,Double count,Double lateTime,Double earlyTime){
                    if(finalTimeList.size()<=1){
                        count +=0.5;
                    }else if(finalTimeList.size()==2){
                        String time1=finalTimeList.get(0);
                        String time2=finalTimeList.get(1);
                        int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                        int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                        int result1=time1.endsWith("1")&&min1<12*60&&time2.endsWith("2")&&min2<12*60?1:0;
                        if(result1==1){
                            if(min1>=9*60||min2<=11*60+15){
                                count++;
                            }else{
                                if(min1>8*60+30&&min1<9*60){
                                    lateTime +=min1 - 8 * 60 - 30;
                                }
                                if(min2>11*60+15&&min2<11*60+45){
                                    earlyTime +=11*60 + 45 - min2;
                                }
                                count +=0.5;
                            }
                        }
                    }
                }
                %>
                <!--处理上月底至本月初的请假数据-->
                <%!
                public static Double getLeaveTime(int num1,String month,String workCode){
                        Double cnt7=0.0;
                        String leaveSql1=" select end_date,end_time from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') and " +
                         " type=" + num1 + " and start_date not like '%" + month + "%' and end_date like '%" + month + "%' ";
                        RecordSet recordSet1 = new RecordSet();
                        recordSet1.executeSql(leaveSql1);
                        if(recordSet1.next()){
                            String sDate=month +"-01";
                            String endDate=recordSet1.getString(1);
                            String endTime=recordSet1.getString(2);
                            //查询出月初至截止请假日期（不包含截止请假日期）的请假数据
                            String combineSql="SELECT case when count(*) is null then 0 else count(*)*7.5 end from uf_attendance where curdate>='"+sDate+"'  and curdate<'"+endTime+"' " +
                             "and week<=5 and isattendance=0 union all SELECT case when count(*) is null then 0 else count(*)*3.25 end  from uf_attendance where curdate>='"+sDate+"'  and curdate<'"+endTime+"' " +
                              "and week=6 and isattendance=0 ";
                            RecordSet recordSet2 = new RecordSet();
                            recordSet2.executeSql(combineSql);
                            while (recordSet1.next()){
                                String s1=recordSet2.getString(1);
                                cnt7 +=Double.parseDouble(s1);
                            }
                            //查询出截止请假日期当天的请假数据
                            cnt7 +=getHour(endDate,endTime);
                        }
                        return cnt7;
                }
                %>
                <!--查询出截止请假日期当天的请假数据-->
                <%!
                public static Double getHour(String endDate,String endTime){
                    Double cnt8=0.0;
                    String endDateSql="select week,isattendance from uf_attendance where curdate='"+endDate+"'  ";
                    RecordSet recordSet2 =new RecordSet();
                    recordSet2.executeSql(endDateSql);
                    while(recordSet2.next()){
                        int week=recordSet2.getInt(1);
                        int isattendance=recordSet2.getInt(2);

                        int endMin=Integer.parseInt(endTime.substring(0,2))*60+Integer.parseInt(endTime.substring(3,5));
                        if(week<=5&&isattendance==0){
                            if(endMin>=8*60+30&&endMin<11*60+45){
                                cnt8 +=(endMin-8*60-30)/60;
                            }else if(endMin>=11*60+45&&endMin<=13*60+15){
                                cnt8 +=3.25;
                            }else if(endMin>13*60+15&&endMin<17*60+15){
                                cnt8 +=(endMin-8*60-30-90)/60;
                            }else if(endMin>=17*60+15){
                                cnt8 +=7.25;
                            }
                        }else if(week==6&& isattendance==0){
                            if(endMin>=8*60+30&&endMin<11*60+45){
                                cnt8 +=(endMin-8*60-30)/60;
                            }else if(endMin>=11*60+45){
                                cnt8 +=3.25;
                            }
                        }
                    }
                        return cnt8;
                }
                %>
                <!--处理本月底至下月初的请假数据-->
                <%!
                public static Double getLeaveTime1(int num1,String month,String workCode){
                    Double cnt7=0.0;
                    //获取本月底至下月初的数据
                    String leaveSql2 = " select start_date,start_time from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') " +
                            "and type=" + num1 + " and start_date like '%" + month + "%' and end_date not like '%" + month + "%'";
                    RecordSet recordSet3 = new RecordSet();
                    recordSet3.executeSql(leaveSql2);
                    if (recordSet3.next()) {
                        String eDate = month + "-31";
                        String startDate = recordSet3.getString(1);
                        String startTime = recordSet3.getString(2);
                        //查询出月初至截止请假日期（不包含截止请假日期）的请假数据
                        String combineSql = "SELECT case when count(*) is null then 0 else count(*)*7.5 end from uf_attendance where curdate<='" + eDate + "'  and curdate>='" + startDate + "' " +
                                "and week<=5 and isattendance=0 union all SELECT case when count(*) is null then 0 else count(*)*3.25 end  from uf_attendance where curdate>='" + eDate + "'  and curdate<'" + startDate + "' " +
                                "and week=6 and isattendance=0 ";
                        RecordSet recordSet4 = new RecordSet();
                        recordSet4.executeSql(combineSql);
                        while (recordSet4.next()) {
                            String s1 = recordSet4.getString(1);
                            cnt7 += Double.parseDouble(s1);
                        }
                        //查询出截止请假日期当天的请假数据
                        cnt7 += getNewHour(startDate, startTime);
                    }
                    return cnt7;
                }
                %>
                <!--查询出截止请假日期当天的请假数据-->
                <%!
                    public static Double getNewHour(String startDate,String startTime){
                        Double cnt8=0.0;
                        String startDateSql="select week,isattendance from uf_attendance where curdate='"+startDate+"'  ";
                        RecordSet recordSet2 =new RecordSet();
                        recordSet2.executeSql(startDateSql);
                        while(recordSet2.next()){
                            int week=recordSet2.getInt(1);
                            int isattendance=recordSet2.getInt(2);
                            int startMin=Integer.parseInt(startTime.substring(0,2))*60+Integer.parseInt(startTime.substring(3,5));
                            if(week<=5&&isattendance==0){
                                if(startMin>=8*60+30&&startMin<11*60+45){
                                    cnt8 +=(startMin-8*60-30)/60;
                                }else if(startMin>=11*60+45&&startMin<=13*60+15){
                                    cnt8 +=3.25;
                                }else if(startMin>13*60+15&&startMin<17*60+15){
                                    cnt8 +=(startMin-8*60-30-90)/60;
                                }else if(startMin>=17*60+15){
                                    cnt8 +=7.25;
                                }
                            }else if(week==6&& isattendance==0){
                                if(startMin>=8*60+30&&startMin<11*60+45){
                                    cnt8 +=(startMin-8*60-30)/60;
                                }else if(startMin>=11*60+45){
                                    cnt8 +=3.25;
                                }
                            }
                        }
                        return cnt8;
                    }
                %>
            </table>
        </div>
        </body>
        </html>
