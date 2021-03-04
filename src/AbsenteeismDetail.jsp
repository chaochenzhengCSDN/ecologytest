<!-- 旷工明细表 -->
<%@ page language="java" import="weaver.iiot.grouptow.common.LeaveCommonController" pageEncoding="UTF-8" %>
<%@page import="java.text.DecimalFormat" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ include file="/hrm/header.jsp" %>
<jsp:useBean id="BaseBean" class="weaver.general.BaseBean" scope="page"/>
<%
    String id = Util.null2String(request.getParameter("userId"));
    String month = Util.null2String(request.getParameter("month"));
    String imagefilename = "/images/hdReport_wev8.gif", needfav = "1", needhelp = "";
    String titlename = "员工旷工明细表";
    BaseBean b = new BaseBean();

    Date curDate = new Date();
    SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy-MM-dd");
    String curDate1 = simpleDateFormat.format(curDate);

    //获取日历类对象
    String[] result = month.split("-");
    String month2 = result[1];
    String year2 = result[0];
    int month3 = Integer.parseInt(month2);
    int year3 = Integer.parseInt(year2);
    Calendar c = Calendar.getInstance();
    c.set(year3, month3 - 1, 1);
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
    String checkMinDate = sdf.format(c.getTime());
    String likeDate = checkMinDate.substring(0, 7);
    c.add(Calendar.MONTH, +1);
    c.add(Calendar.DATE, -1);
    String checkMaxDate = sdf.format(c.getTime());
%>
<style type="text/css">
    * {
        margin: 0;
        padding: 0;
        border: 0;
        list-style-type: none;
        font-size: 11px;
    }

    td, th {
        border: 1px solid #90BADD;
        height: 30px;
        text-align: center;
    }

    th {
        font-weight: bold;
    }

    .btn {
        height: 30px;
        width: 1100px;
        border: 1px solid black;
        background-color: white;
    }

    #tablecontainer, #tablecontainer1 {
        width: 100%;
        height: 400px;
        margin: 0 auto;
    }

    body {
        position: relative;
    }

    .rightSearchSpan {
        position: absolute;
        right: 50px;
        top: 5px;
    }

    .e8_btn_top_a:hover {
        color: #FFFFFF !important;
        background-color: #03a996;
    }

    .e8_btn_top_a {
        border: 1px solid #aecef1;
        color: #1098ff !important;
        background-color: #FFF;
        padding: 2px 5px;
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
        LeaveCommonController leaveCommonController=new LeaveCommonController();
        Map<String, Double> abnormalMap = new TreeMap<String, Double>();//接收旷工数据
        List<String> curdateList = new ArrayList<String>(); //查询当月应出勤日期 周一至周五
        List<String> curdateList1 = new ArrayList<String>();//用于接收当前日期存在打卡记录的集合
        double countHours=0.0;//上午旷工小时数
        double countHours1=0.0;//下午旷工小时数
        double countHours2=0.0;//周六旷工小时数
        DecimalFormat df11=new DecimalFormat("0.00");//设置保留位数
        String curdateSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus=0";
        //处理合同开始时间在当月或合同结束时间在当月
        String startDateSql="select startdate from hrmresource where id='"+id+"'";
        String contractStartDate=getName(startDateSql);
        //如果合同开始时间为空，则赋值为2000-01-01
        contractStartDate =(contractStartDate==null||contractStartDate.isEmpty())?"2000-01-01":contractStartDate;
        String endDateSql="select enddate from hrmresource where id='"+id+"'";
        String contractEndDate=getName(endDateSql);
        //如果合同开始结束为空，则赋值为2100-01-01
        contractEndDate =(contractEndDate==null||contractEndDate.isEmpty())?"2100-01-01":contractEndDate;
        if(month.equals(contractStartDate.substring(0,7))){
            curdateSql +=" and curdate >= '"+contractStartDate+"' ";
        }
        if(month.equals(contractEndDate.substring(0,7))){
            curdateSql +=" and curdate <= '"+contractEndDate+"' ";
        }
        RecordSet rs6 = new RecordSet();
        rs6.executeSql(curdateSql);
        while (rs6.next()) {
            String curdate = rs6.getString(1);
            curdateList.add(curdate);
        }
        //查询当月应出勤日期 周六  //2020.04.19 zcc查出事假，赋值当天旷工为0.5 确认 事假小时数/7.5*0.5
        List<String> saturdayList = new ArrayList<String>();
        List<String> saturdayList1 = new ArrayList<String>();//用于接收当前存在打卡记录的集合
        String saturdayForWorkSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus=2";
        if(month.equals(contractStartDate.substring(0,7))){
            saturdayForWorkSql +=" and curdate >= '"+contractStartDate+"' ";
        }
        if(month.equals(contractEndDate.substring(0,7))){
            saturdayForWorkSql +=" and curdate <= '"+contractEndDate+"' ";
        }
        RecordSet rs7 = new RecordSet();
        rs7.executeSql(saturdayForWorkSql);
        while (rs7.next()) {
            String curdate = rs7.getString(1);
            saturdayList.add(curdate);
        }
        String signSql = "SELECT hsc.signDate,hsc.signTime,hsc.signType FROM hrmresource hre LEFT JOIN hrmschedulesign hsc ON hre.id =  hsc.userid " +
                "AND signDate like '%" + month + "%' AND hsc.isInCom = '1' LEFT JOIN hrmdepartment hde ON hre.departmentid = hde.id  " +
                "WHERE hre.accounttype = 0 AND  hre.id = '" + id + "'";
        //b.writeLog("查询sql语句:" + signSql);
        RecordSet signRecordSet = new RecordSet();
        Map<String, List<String>> value = getAreaResult(signSql, signRecordSet);
        //调用方法，改变出差时的打卡时间
        changeBusinessTripTime(value, checkMinDate, checkMaxDate, id, likeDate, "1", "2");
        //调用方法，改变异常考勤时的打卡时间
        changeAbnormalSignTime(value, id, month);
        //调用方法，改变请假(调休)的打卡时间
        leaveCommonController.changeLeaveTime(value, id,likeDate,8,"3","4");
        //调用方法，改变请假(年假)的打卡时间
        leaveCommonController.changeLeaveTime(value, id,likeDate,0,"3","4");
        //调用方法，改变请假(事假)的打卡时间
        leaveCommonController.changeLeaveTime(value, id,likeDate,9,"5","6");
        b.writeLog("请假处理后："+value);
    %>
    <tr>
        <th align='center'>旷工日期</th>
        <th align='center'>旷工(小时数)</th>
        <th align='center'>旷工类别</th>
    </tr>
    <%
        //判断value集合是否为空
        if (value !=null && !value.isEmpty()) {
            //获取结果集所有键的集合，用keySet()方法实现
            Set<String> valueSet = value.keySet();
            //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
            TreeSet<String> ts1 = getDateTreeSet();
            ts1.addAll(valueSet);
            //遍历键的集合，获取到每一个键。用增强for实现
            for (String key1 : ts1) {
                if (Integer.parseInt(key1.split("-")[1]) == Integer.parseInt(month.split("-")[1])) {
                    //根据键去找值，用get(Object key)方法实现
                    List<String> timeList = value.get(key1);
                    Collections.sort(timeList);
                    //调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
                    List<String> morningTimeList = getMorningTimeList(timeList);
                    //调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
                    List<String> afternoonTimeList = getAfternoonTimeList(timeList);
                    //调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
                    List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);
                    //调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
                    List<String> finalTimeList = getFinalTimeList(morningTimeList, afternoonTimeList, confirmTimeList);
                    //b.writeLog("当天为:" + key1 + ";打卡最终信息:" + finalTimeList);

                    //对哺乳假数据进行处理
                    List<String> newFinalTimeList = reviseFinalTimeList(finalTimeList, key1, id);
                    if (curdateList.contains(key1)) {
                        List<String> morningList1 = new LinkedList<String>();
                        List<String> afternoonList1 = new LinkedList<String>();
                        for (String time5 : newFinalTimeList) {
                            int time5ForMin = getTimeMin(time5, 0) * 60 + getTimeMin(time5, 1);
                            if (time5ForMin < 720) {
                                morningList1.add(time5);
                                Collections.sort(morningList1);
                            } else {
                                afternoonList1.add(time5);
                                Collections.sort(afternoonList1);
                            }
                        }
                        //b.writeLog("当天日期:" + key1 + "<---->当天上午打卡情况:" + morningList1 + "<---->当天打卡大小：" + morningList1.size());
                        for (String time6 : morningList1) {
                            if (time6.endsWith("1") && (time6.compareTo("11:45:00:1") > 0)) {
                                morningList1.remove(time6);
                                break;
                            }
                        }

                        /*
                         *
                         * 计算带请假的迟到早退旷工小时数(周一-----周五上午)
                         *
                         * */
                        if (morningList1.size() <= 1) {
                            //旷工小时数
                            countHours = 3.25;
                            abnormalMap.put(key1 + "-1", countHours);
                        } else if (morningList1.size() == 2) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //上午两次打卡数据 则计算迟到早退 08:30:00:1 09:30:00:2
                                //不做任何操作
                            } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //上午两次打卡记录， 08:30:00:1 11:00:00:4
                                countHours = ((705 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - secondSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //上午两次请假数据 则计算旷工小数 08:30:00:3, 11:45:00:4
                                countHours = (((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0) + (((705 - secondSignForMin) >= 0) ? Double.valueOf(df11.format((float) (705 - secondSignForMin) / 60)) : 0);
                                abnormalMap.put(key1 + "-1", countHours);
                            } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //上午两次打卡记录， 08:30:00:3 11:30:00:2
                                countHours = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            }
                        } else if (morningList1.size() == 3) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //第三次打卡
                            String thirdSign = morningList1.get(2);
                            //第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            if (firstSign.endsWith("1")) {
                                //上午三条记录 08：30：00：1  10：00：00：3 11：45：00：4
                                //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                countHours = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                countHours += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                                countHours += ((705 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            } else if (thirdSign.endsWith("1")) {
                                //上午三条记录 08：30：00：3  10：00：00：4 11：00：00：1
                                //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                countHours = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                countHours += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                                countHours += ((705 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            }
                        } else if (morningList1.size() == 4) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //第三次打卡
                            String thirdSign = morningList1.get(2);
                            //第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            //第四次打卡
                            String forthSign = morningList1.get(3);
                            //第四次打卡对应的分钟数
                            int forthSignForMin = getTimeMin(forthSign, 0) * 60 + getTimeMin(forthSign, 1);
                            if (firstSign.endsWith("1")) {
                                //08：30：00：1 09:30:00:2 10：00：00：3 11：00：00：4
                                countHours = ((705 - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - forthSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            } else if (thirdSign.endsWith("1")) {
                                //上午四条记录 08：40：00：3 09:30:00:4 10：00：00：1 11：00：00：2
                                countHours = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                abnormalMap.put(key1 + "-1", countHours);
                            }
                        }
                        //b.writeLog("当天日期:" + key1 + "当天上午旷工小时数:" + countHours);
                        List<String> afternoonList2 = new LinkedList<String>();
                        b.writeLog("下午afternoonList1:"+afternoonList1);
                        for (String time6 : afternoonList1) {
                            if (time6.endsWith("1") && (time6.compareTo("17:15:00:1") > 0)) {
                                afternoonList1.remove(time6);
                                break;
                            }
                        }
                        for (String clockOut : afternoonList1) {
                            if (clockOut.endsWith("2")||clockOut.endsWith("4")||clockOut.endsWith("6")||clockOut.endsWith("8")) {
                                afternoonList2.add(clockOut);
                            }
                        }
                        int afternoonList1Size = afternoonList1.size();
                        afternoonList1Size = (afternoonList2.size() >= 2) ? (afternoonList1Size - afternoonList2.size() + 1) : afternoonList1Size;
                        /*
                         *
                         * 计算带请假的迟到早退旷工小时数(周一-----周五下午)
                         *
                         * */
                        if (afternoonList1Size <= 1) {
                            countHours1 = 4.25;
                            abnormalMap.put(key1 + "-2", countHours1);
                        } else if (afternoonList1Size == 2) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //下午两次打卡数据 则计算迟到早退 13:30:00:1 17:00:00:2
                                //不做操作
                            } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //下午两次打卡记录， 14:00:00:1 16:00:00:4
                                countHours1 = ((1035 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (1035 - secondSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-2", countHours1);
                            } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //下午两次请假数据 则计算旷工小数  14:00:00:3 16:00:00:4
                                countHours1 = (((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0) +
                                        (((1035 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (1035 - secondSignForMin) / 60)) : 0);
                                abnormalMap.put(key1 + "-2", countHours1);
                            } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //下午两次打卡记录， 14:00:00:3 16:15:00:2
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                            }
                        } else if (afternoonList1Size == 3) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //下午第三次打卡
                            String thirdSign = afternoonList1.get(2);
                            //下午第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            if (firstSign.endsWith("1")) {
                                //上午三条记录 13：30：00：1  15：00：00：3 17：00：00：4
                                //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                countHours1 += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                                countHours1 += ((1035 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (1035 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-2", countHours1);
                            } else if (thirdSign.endsWith("1")) {
                                //上午三条记录 13：30：00：3  15：00：00：4 17：00：00：1
                                //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                countHours1 += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                                countHours1 += ((1035 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (1035 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-2", countHours1);
                            }
                        } else if (afternoonList1Size >= 4) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //下午第三次打卡
                            String thirdSign = afternoonList1.get(2);
                            //下午第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            //下午第四次打卡
                            String forthSign = afternoonList1.get(3);
                            //下午第四次打卡对应的分钟数
                            int forthSignForMin = getTimeMin(forthSign, 0) * 60 + getTimeMin(forthSign, 1);
                            if (firstSign.endsWith("1")) {
                                //下午四条记录13：30：00：1 15:30:00:2 16：00：00：3 17：00：00：4
                                countHours1 = ((1035 - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (1035 - forthSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-2", countHours1);
                            } else if (thirdSign.endsWith("1")) {
                                //下午四条记录 13：30：00：3 15:30:00:4 16：00：00：1 17：00：00：2
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                abnormalMap.put(key1 + "-2", countHours1);
                            }
                        }
                        //b.writeLog("当天日期:" + key1 + ";当天下午旷工:" + countHours1);
                        curdateList1.add(key1);
                    } else if (saturdayList.contains(key1)) {
                        List<String> morningList1 = new LinkedList<String>();
                        List<String> afternoonList1=new LinkedList<String>();
                        for (String time5 : newFinalTimeList) {
                            int time5ForMin = getTimeMin(time5, 0) * 60 + getTimeMin(time5, 1);
                            if (time5ForMin < 720) {
                                morningList1.add(time5);
                                Collections.sort(morningList1);
                            }else{
                                afternoonList1.add(time5);
                                Collections.sort(afternoonList1);
                            }
                        }
                        for (String time6 : morningList1) {
                            if (time6.endsWith("1") && (time6.compareTo("11:45:00:1") > 0)) {
                                morningList1.remove(time6);
                                break;
                            }
                        }
                        /*
                         *
                         * 计算带请假的迟到早退旷工小时数(周六上午)
                         *
                         * */
                        if (morningList1.size() <= 1) {
                            //旷工小时数
                            countHours2 = 3.25;
                            abnormalMap.put(key1 + "-3", countHours2*2);
                        } else if (morningList1.size() == 2) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //上午两次打卡数据 则计算迟到早退 08:30:00:1 09:30:00:2
                                //不做操作
                            } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //上午两次打卡记录， 08:30:00:1 11:00:00:4
                                countHours2 = ((705 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - secondSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //上午两次请假数据 则计算旷工小数 08:30:00:3, 11:45:00:4
                                countHours2 = (((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0) + (((705 - secondSignForMin) >= 0) ? Double.valueOf(df11.format((float) (705 - secondSignForMin) / 60)) : 0);
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //上午两次打卡记录， 08:30:00:3 11:30:00:2
                                countHours2 = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            }
                        } else if (morningList1.size() == 3) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //第三次打卡
                            String thirdSign = morningList1.get(2);
                            //第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            if (firstSign.endsWith("1")) {
                                //上午三条记录 08：30：00：1  10：00：00：3 11：45：00：4
                                //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                countHours2 = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                countHours2 += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                                countHours2 += ((705 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            } else if (thirdSign.endsWith("1")) {
                                //上午三条记录 08：30：00：3  10：00：00：4 11：00：00：1
                                //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                countHours2 = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                countHours2 += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                                countHours2 += ((705 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            }
                        } else if (morningList1.size() == 4) {
                            //第一次打卡
                            String firstSign = morningList1.get(0);
                            //第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //第二次打卡
                            String secondSign = morningList1.get(1);
                            //第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //第三次打卡
                            String thirdSign = morningList1.get(2);
                            //第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            //第四次打卡
                            String forthSign = morningList1.get(3);
                            //第四次打卡对应的分钟数
                            int forthSignForMin = getTimeMin(forthSign, 0) * 60 + getTimeMin(forthSign, 1);
                            if (firstSign.endsWith("1")) {
                                //08：30：00：1 09:30:00:2 10：00：00：3 11：00：00：4
                                countHours2 = ((705 - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (705 - forthSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            } else if (thirdSign.endsWith("1")) {
                                //上午四条记录 08：40：00：3 09:30:00:4 10：00：00：1 11：00：00：2
                                countHours2 = ((firstSignForMin - 510) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 510) / 60)) : 0;
                                abnormalMap.put(key1 + "-3", countHours2*2);
                            }
                        }
                        //b.writeLog("周六日期:" + key1 + ";周六旷工:" + countHours2*2);
                        List<String> afternoonList2 = new LinkedList<String>();
                        b.writeLog("下午afternoonList1:"+afternoonList1);
                        for (String time6 : afternoonList1) {
                            if (time6.endsWith("1") && (time6.compareTo("16:15:00:1") > 0)) {
                                afternoonList1.remove(time6);
                                break;
                            }
                        }
                        for (String clockOut : afternoonList1) {
                            if (clockOut.endsWith("2")||clockOut.endsWith("4")||clockOut.endsWith("6")||clockOut.endsWith("8")) {
                                afternoonList2.add(clockOut);
                            }
                        }
                        int afternoonList1Size = afternoonList1.size();
                        afternoonList1Size = (afternoonList2.size() >= 2) ? (afternoonList1Size - afternoonList2.size() + 1) : afternoonList1Size;
                        /*
                         *
                         * 计算带请假的迟到早退旷工小时数(周一-----周五下午)
                         *
                         * */
                        if (afternoonList1Size <= 1) {
                            countHours1 = 3.25;
                            abnormalMap.put(key1 + "-4", countHours1*2);
                        } else if (afternoonList1Size == 2) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            if (firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //下午两次打卡数据 则计算迟到早退 13:30:00:1 17:00:00:2
                                //不做操作
                            } else if (firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //下午两次打卡记录， 14:00:00:1 16:00:00:4
                                countHours1 = ((975 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (975 - secondSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            } else if (!firstSign.endsWith("1") && !secondSign.endsWith("2")) {
                                //下午两次请假数据 则计算旷工小数  14:00:00:3 16:00:00:4
                                countHours1 = (((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0) +
                                        (((975 - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (975 - secondSignForMin) / 60)) : 0);
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            } else if (!firstSign.endsWith("1") && secondSign.endsWith("2")) {
                                //下午两次打卡记录， 14:00:00:3 16:15:00:2
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                            }
                        } else if (afternoonList1Size == 3) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //下午第三次打卡
                            String thirdSign = afternoonList1.get(2);
                            //下午第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            if (firstSign.endsWith("1")) {
                                //上午三条记录 13：30：00：1  15：00：00：3 17：00：00：4
                                //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                countHours1 += ((secondSignForMin - firstSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (secondSignForMin - firstSignForMin) / 60)) : 0;
                                countHours1 += ((975 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (975 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            } else if (thirdSign.endsWith("1")) {
                                //上午三条记录 13：30：00：3  15：00：00：4 17：00：00：1
                                //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                countHours1 += ((thirdSignForMin - secondSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (thirdSignForMin - secondSignForMin) / 60)) : 0;
                                countHours1 += ((975 - thirdSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (975 - thirdSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            }
                        } else if (afternoonList1Size >= 4) {
                            //下午第一次打卡
                            String firstSign = afternoonList1.get(0);
                            //下午第一次打卡对应的分钟数
                            int firstSignForMin = getTimeMin(firstSign, 0) * 60 + getTimeMin(firstSign, 1);
                            //下午第二次打卡
                            String secondSign = afternoonList1.get(1);
                            //下午第二次打卡对应的分钟数
                            int secondSignForMin = getTimeMin(secondSign, 0) * 60 + getTimeMin(secondSign, 1);
                            //下午第三次打卡
                            String thirdSign = afternoonList1.get(2);
                            //下午第三次打卡对应的分钟数
                            int thirdSignForMin = getTimeMin(thirdSign, 0) * 60 + getTimeMin(thirdSign, 1);
                            //下午第四次打卡
                            String forthSign = afternoonList1.get(3);
                            //下午第四次打卡对应的分钟数
                            int forthSignForMin = getTimeMin(forthSign, 0) * 60 + getTimeMin(forthSign, 1);
                            if (firstSign.endsWith("1")) {
                                //下午四条记录13：30：00：1 15:30:00:2 16：00：00：3 17：00：00：4
                                countHours1 = ((975 - forthSignForMin) >= 0) ? Double.parseDouble(df11.format((float) (975 - forthSignForMin) / 60)) : 0;
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            } else if (thirdSign.endsWith("1")) {
                                //下午四条记录 13：30：00：3 15:30:00:4 16：00：00：1 17：00：00：2
                                countHours1 = ((firstSignForMin - 780) > 0) ? Double.parseDouble(df11.format((float) (firstSignForMin - 780) / 60)) : 0;
                                abnormalMap.put(key1 + "-4", countHours1*2);
                            }
                        }
                        saturdayList1.add(key1);
                    }
                }
            }
            curdateList.removeAll(curdateList1);
            saturdayList.removeAll(saturdayList1);
            //b.writeLog("111111111" + curdateList);
            for (String time7 : curdateList) {
                time7 = time7 + "-1";
                abnormalMap.put(time7, 3.25);
            }
            for (String time8 : curdateList) {
                time8 = time8 + "-2";
                abnormalMap.put(time8, 4.25);
            }
            for (String time9 : saturdayList) {
                time9 = time9 + "-3";
                abnormalMap.put(time9, 6.5);
            }
            for (String time10 : saturdayList) {
                time10 = time10 + "-4";
                abnormalMap.put(time10, 6.5);
            }
            //b.writeLog("异常集合为：" + abnormalMap);

            if (abnormalMap.size() != 0) {
                for (String abnormalDay : abnormalMap.keySet()) {
                    Double abnormalHour = abnormalMap.get(abnormalDay);
                    if (abnormalHour != 0.0) {
                        out.println("<tr><td align='center'>" + abnormalDay.substring(0, 10) + "</td><td align='center'>" + abnormalHour + "</td>");
                        if (("1").equals(abnormalDay.split("-")[3])) {
                            out.println("<td align='center'>工作日上午</td>");
                        } else if (("2").equals(abnormalDay.split("-")[3])) {
                            out.println("<td align='center'>工作日下午</td>");
                        } else if (("3").equals(abnormalDay.split("-")[3])) {
                            out.println("<td align='center'>单休周六上午</td>");
                        } else if (("4").equals(abnormalDay.split("-")[3])) {
                            out.println("<td align='center'>单休周六下午</td>");
                        }
                        out.println("</tr>");
                    }
                }
            } else {
                out.println("<tr>");
                out.println("<th colspan='3' style='font-size:18px;height:80px;' align='center'>无查询结果，请确认查询报表条件</td>");
                out.println("</tr>");
            }
        }else {
            for (String time7 : curdateList) {
                time7 = time7 + "-1";
                abnormalMap.put(time7, 3.25);
            }
            for (String time8 : curdateList) {
                time8 = time8 + "-2";
                abnormalMap.put(time8, 4.25);
            }
            for (String time9 : saturdayList) {
                time9 = time9 + "-3";
                abnormalMap.put(time9, 6.5);
            }
            for (String time10 : saturdayList) {
                time10 = time10 + "-4";
                abnormalMap.put(time10, 6.5);
            }
            for (String abnormalDay : abnormalMap.keySet()) {
                Double abnormalHour = abnormalMap.get(abnormalDay);
                out.println("<tr><td align='center'>" + abnormalDay.substring(0, 10) + "</td><td align='center'>" + abnormalHour + "</td>");
                if (("1").equals(abnormalDay.split("-")[3])) {
                    out.println("<td align='center'>工作日上午</td>");
                } else if (("2").equals(abnormalDay.split("-")[3])) {
                    out.println("<td align='center'>工作日下午</td>");
                } else if (("3").equals(abnormalDay.split("-")[3])) {
                    out.println("<td align='center'>单休周六上午</td>");
                } else if (("4").equals(abnormalDay.split("-")[3])) {
                    out.println("<td align='center'>单休周六下午</td>");
                }
                out.println("</tr>");
            }
        }
    %>
    <%!
        public static Long getTimeMillis(Calendar c) {
            c.set(Calendar.DAY_OF_MONTH, c.get(Calendar.DAY_OF_MONTH) + 1);
            return c.getTimeInMillis();
        }
    %>
    <!-- 获取时间的秒数getTime(String s) -->
    <%!
        public static Integer getTime(String s) {
            String[] arr = s.split(":");
            int hour = Integer.parseInt(arr[0]);
            int minute = Integer.parseInt(arr[1]);
            int seconds = Integer.parseInt(arr[2]);
            return hour * 3600 + minute * 60 + seconds;
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
        public static Map<String, List<String>> getAreaResult(String sql, RecordSet signRecordSet) {
            signRecordSet.executeSql(sql);
            //定义集合，把数据进行封装
            Map<String, List<String>> dateList = new LinkedHashMap<String, List<String>>();
            BaseBean b=new BaseBean();
            //b.writeLog(sql);
            //b.writeLog(dateList);
            while (signRecordSet.next()) {
                String signDate = Util.null2String(signRecordSet.getString("signDate"));//考勤日期
                String signTime = Util.null2String(signRecordSet.getString("signTime"));//考勤时间
                String signType = Util.null2String(signRecordSet.getString("signType"));//考勤类型
                if (!signTime.isEmpty() && !signType.isEmpty()) {
                    signTime = signTime + ":" + signType;
                }
                //有打卡记录
                if(!signDate.isEmpty()){
                    //如果当前日期、打卡记录集合包含当天数据
                    if (dateList.containsKey(signDate)) {
                        dateList.get(signDate).add(signTime);
                    } else {
                        //不是同一天
                        List<String> timeList1 = new ArrayList<String>();
                        if(!signTime.isEmpty()){
                            timeList1.add(signTime);
                        }
                        dateList.put(signDate, timeList1);
                    }
                }
            }
            //b.writeLog(dateList);
            return dateList;
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
            //定义下午17:15时段之前的最终打卡时间的集合
            List<String> finalAfternoonTimeList = new ArrayList<String>();
            ////b.writeLog("afternoonTimeList:"+afternoonTimeList);
            List<String> afternoonTimeList1 = new ArrayList<String>();
            List<String> leaveTimeList = new ArrayList<String>();
            for (String cTime : afternoonTimeList) {
                if (cTime.endsWith("1") || cTime.endsWith("2")) {
                    afternoonTimeList1.add(cTime);
                } else {
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
                    finalAfternoonTimeList.add(time2);
                    //1.3如果最后一次打卡在17:15:00之后则取下午时段的第一次打卡的时间和17:15:00之后打卡的时间
                }
                if ((y == 0 && typeInt == 1) || (y == 0 && afternoonTimeList1.size() == 1)) {
                    finalAfternoonTimeList.add(time);
                }
            }
            for (String time2 : leaveTimeList) {
                int time2ForMin = Integer.parseInt(time2.split(":")[0]) * 60 + Integer.parseInt(time2.split(":")[1]);
                if (time2ForMin < 17 * 60 + 15) {
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
            List<String> finalTimeList = new ArrayList<String>();
            BaseBean b = new BaseBean();
            //遍历上午时段的打卡集合
            finalTimeList.addAll(morningTimeList);
            //遍历下午17:15时段之前的最终打卡集合
            List<String> finalAfternoonTimeList = getFinalAfternoonTimeList(afternoonTimeList);
            finalTimeList.addAll(finalAfternoonTimeList);
            //遍历下午时段17:15:00之后的时间集合
            List<String> finalCofirmTimeList = getFinalCofirmTimeList(confirmTimeList);
            finalTimeList.addAll(finalCofirmTimeList);
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
            List<String> businesstripTimeList2 = new ArrayList<String>();//全天标准打卡数据 上午签退时间 下午签到时间 下午签退时间
            businesstripTimeList2.add("11:45:00:" + businessOutFlag);
            businesstripTimeList2.add("13:00:00:" + businessinFlag);
            businesstripTimeList2.add("17:15:00:" + businessOutFlag);
            List<String> businesstripTimeList3 = new ArrayList<String>();//全天标准打卡数据 下午签到时间 下午签退时间
            businesstripTimeList3.add("13:00:00:" + businessinFlag);
            businesstripTimeList3.add("17:15:00:" + businessOutFlag);
            List<String> businesstripTimeList4 = new ArrayList<String>();//全天标准打卡数据 下午签退时间
            businesstripTimeList4.add("17:15:00:" + businessOutFlag);
            List<String> businesstripTimeList5 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间 下午签到时间
            businesstripTimeList5.add("08:30:00:" + businessinFlag);
            businesstripTimeList5.add("11:45:00:" + businessOutFlag);
            businesstripTimeList5.add("13:00:00:" + businessinFlag);
            List<String> businesstripTimeList6 = new ArrayList<String>();//全天标准打卡数据 上午签到时间 上午签退时间
            businesstripTimeList6.add("08:30:00:" + businessinFlag);
            businesstripTimeList6.add("11:45:00:" + businessOutFlag);
            List<String> businesstripTimeList7 = new ArrayList<String>();//全天标准打卡数据 上午签到时间
            businesstripTimeList7.add("08:30:00:" + businessinFlag);
            String sql1 = "SELECT start_date,start_time,end_date,end_time from uf_BusinessTrip WHERE userid = " + id + " and (start_date like '%" + month + "%' or end_date like '%" + month + "%') ORDER BY start_date";
            RecordSet rs1 = new RecordSet();
            rs1.executeSql(sql1);
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
                        int isAttendance1 = getId(attendanceSql1, "OA");
                        if (isAttendance1 >= 1) {
                            value.put(businesstripDate, businesstripTimeList1);
                        }
                    }
                    //b.writeLog("出差是否只有一天:" + startDate.equals(endDate));
                    //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                    String attendanceSql2 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + startDate + "'";
                    String attendanceSql3 = "SELECT count(*) count from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + endDate + "'";
                    ////b.writeLog("出差开始日期是否有打卡记录:"+attendanceSql2);
                    int isAttendance2 = getId(attendanceSql2, "OA");
                    int isAttendance3 = getId(attendanceSql3, "OA");
                    //b.writeLog("是否出勤:"+isAttendance2);
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
            rs.executeSql(sql);
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
                //异常类型 上午签到 添加上午签到标准时间 上午签退 添加上午签退标准时间 下午签到 添加下午签到标准时间 下午签退 添加下午签退标准时间
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
        /**
         * @param value
         * @param id
         * @param likeDate
         * @param type
         * @param leaveinFlag
         * @param leaveoutFlag
         */
        public static void changeLeaveTime(Map<String, List<String>> value, String id, String likeDate, int type, String leaveinFlag, String leaveoutFlag) {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            BaseBean b = new BaseBean();
            //全天标准打卡数据
            List<String> timeList1 = new ArrayList<String>();
            timeList1.add("08:30:00:" + leaveinFlag);
            timeList1.add("11:45:00:" + leaveoutFlag);
            timeList1.add("13:00:00:" + leaveinFlag);
            timeList1.add("17:15:00:" + leaveoutFlag);
            //上午上班、上午下班标准打卡数据
            List<String> timeList6 = new ArrayList<String>();
            timeList6.add("08:30:00:" + leaveinFlag);
            timeList6.add("11:45:00:" + leaveoutFlag);

            String sql = "SELECT start_date,start_time,end_date,end_time from uf_AskForLeave WHERE type = " + type + " AND userid = " + id + " and (start_date like '%" + likeDate + "%' or end_date like '%" + likeDate + "%') ORDER BY start_date";
            RecordSet rs = new RecordSet();
            rs.execute(sql);
            while (rs.next()) {
                List<String> dateList = new ArrayList<String>();
                List<String> finalDateList = new ArrayList<String>();
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
                        b.writeLog("请假时间段为>>>:"+valueDate+";请假集合为>>>:"+wholeDate);
                        b.writeLog(!valueDate.equals(startDate)&&!valueDate.equals(endDate));
                        b.writeLog(valueDate.equals(startDate)&&!valueDate.equals(endDate));
                        b.writeLog(!valueDate.equals(startDate)&&valueDate.equals(endDate));
                        String attendanceSql = "select attendancestatus from uf_attendance where curdate = '" + valueDate + "'";//根据日期查询排版表
                        int attendancestatus = getId(attendanceSql);
                        //如果当天不为起始日期，也不为截止日期
                        if(!valueDate.equals(startDate)&&!valueDate.equals(endDate)){
                            if (attendancestatus == 0) {
                                //正常出勤1天
                                value.put(valueDate, timeList1);
                            } else if (attendancestatus == 2) {
                                //单休六出勤半天
                                value.put(valueDate, timeList6);
                            }
                        }else
                            //如果当天为起始日期
                            if(valueDate.equals(startDate)&&!valueDate.equals(endDate)){
                                if (attendancestatus == 0) {
                                    //正常出勤1天
                                    String startTime1=startTime;
                                    String endTime1 = "17:15";
                                    changeTodayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                                } else if (attendancestatus == 2) {
                                    //单休六出勤半天
                                    String startTime1=startTime;
                                    String endTime1 = "11:45";
                                    changeSaturdayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                                }
                            }else
                                //如果当天为截止日期
                                if(!valueDate.equals(startDate)&&valueDate.equals(endDate)){
                                    b.writeLog("当天出勤状态attendancestatus为>>>:"+attendancestatus+";请假集合为>>>:"+valueDate);
                                    if (attendancestatus == 0) {
                                        //正常出勤1天
                                        String startTime1="08:30";
                                        String endTime1 = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                                        changeTodayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                                    } else if (attendancestatus == 2) {
                                        //单休六出勤半天
                                        String startTime1="08:30";
                                        String endTime1 = endTime.compareTo("11:45") >= 0 ? "11:45" : endTime;
                                        changeSaturdayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                                    }
                                }
                    }
                }else
                    //请假开始日期和请假结束日期不为同一天
                    if (wholeDate.size()==2) {
                        //----2020.07.13---start---
                        //处理调休(年假)请假开始当天的考勤打卡时间
                        String startDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + startDate + "'";//根据日期查询排版表
                        int startDateStatus = getId(startDateStatusSql);
                        if (startDateStatus == 0) {
                            //正常出勤1天
                            String startTime1=startTime;
                            String endTime1 = "17:15";
                            //b.writeLog("startDate:"+startDate);
                            changeTodayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                        } else if (startDateStatus == 2) {
                            //单休六出勤半天
                            String startTime1=startTime;
                            String endTime1 = "11:45";
                            changeSaturdayTime(value, startTime1, endTime1, startDate, leaveinFlag, leaveoutFlag);
                        }
                        //调休(年假)请假结束日期当天的打卡记录集合
                        String endDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                        int endDateStatus = getId(endDateStatusSql);
                        if (endDateStatus == 0) {
                            //正常出勤1天
                            String startTime1="08:30";
                            String endTime1 = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                            changeTodayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                        } else if (endDateStatus == 2) {
                            //单休六出勤半天
                            String startTime1="08:30";
                            String endTime1 = endTime.compareTo("11:45") >= 0 ? "11:45" : endTime;
                            changeSaturdayTime(value, startTime1, endTime1, endDate, leaveinFlag, leaveoutFlag);
                        }
                        //----2020.07.13---end---
                    } else if (wholeDate.size()==1){
                        //请假开始日期和请假结束日期为同一天
                        String attendanceSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                        int attendancestatus = getId(attendanceSql);
                        if (attendancestatus == 0) {
                            changeTodayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//正常出勤1天
                        } else if (attendancestatus == 2) {
                            changeSaturdayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//单休六出勤半天
                        }
                    }else{}
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
                public static void changeTodayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate, String leaveinFlag, String leaveoutFlag) {
                    //处理外出当天的考勤打卡时间
                    //外出当天的打卡记录集合
                    BaseBean b = new BaseBean();
                    List<String> gooutStartDate = new LinkedList<String>();
                    //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
                    if (value.containsKey(outdate)) {
                        gooutStartDate = value.get(outdate);
                        Collections.sort(gooutStartDate);
                    }
                    int isNumber = gooutStartDate.size();//集合是否为空
                    int startTimeForHours = Integer.parseInt(startTime.split(":")[0]);
                    int startTimeForMinutes = Integer.parseInt(startTime.split(":")[1]);

                    int endTimeForHours = Integer.parseInt(endTime.split(":")[0]);
                    int endTimeForMinutes = Integer.parseInt(endTime.split(":")[1]);

                    //修改zcc 2020.06.20 ---start---
                    startTime = startTime + ":00:" + leaveinFlag;//将请假开始时间变成打卡签到时间
                    startTime = startTime.compareTo("08:30:00:" + leaveinFlag) <= 0 ? ("08:30:00:" + leaveinFlag) : startTime;
                    endTime = endTime + ":00:" + leaveoutFlag;//将请假结束时间变成打卡签退时间
                    endTime = endTime.compareTo("17:15:00:" + leaveoutFlag) >= 0 ? ("17:15:00:" + leaveoutFlag) : endTime;
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
                        if (isNumber > 0) {
                            //当天是否有打卡记录
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                //取出请假当天上午签到数据
                                if (signTime.endsWith("1") && signForHour < 12) {
                                    oldSignInList.add(signTime);
                                }
                            }
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//有打卡时间则取第一次签到时间 否则赋值为空
                            //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                            if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                                //修改zcc 2020.06.20 ---start---
                                gooutStartDate.add(startTime);
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                        //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                    } else if (result3) {
                        //外出开始时间小于等于8:30,外出时间小于13:00
                        gooutStartDate.add("08:30:00:" + leaveinFlag);
                        gooutStartDate.add("11:45:00:" + leaveoutFlag);
                        value.put(outdate, gooutStartDate);
                    } else if (result4) {
                        //请假开始时间小于等于8:30,外出时间小于17:15
                        if (isNumber > 0) {
                            List<String> oldSignInList = new ArrayList<String>();//定义下午签到记录
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                if (signTime.endsWith("1") && signForHour >= 12) {
                                    oldSignInList.add(signTime);
                                }
                            }
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//有打卡时间则取第一次签到时间 否则赋值为空
                            //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                            if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                                //修改zcc 2020.06.22 ---start---
                                gooutStartDate.add(startTime);
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            //当天无打卡记录
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            gooutStartDate.add("11:45:00:" + leaveoutFlag);
                            gooutStartDate.add("13:00:00:" + leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }
                        //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                    } else if (result5) {
                        //外出开始时间小于等于8:30,外出时间大于等于17:15
                        b.writeLog("标识1的值:"+leaveinFlag+"标识2的值:"+leaveoutFlag);
                        gooutStartDate.add("08:30:00:" + leaveinFlag);
                        gooutStartDate.add("11:45:00:" + leaveoutFlag);
                        gooutStartDate.add("13:00:00:" + leaveinFlag);
                        gooutStartDate.add("17:15:00:" + leaveoutFlag);
                        value.put(outdate, gooutStartDate);
                    } else if (result6) {
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
                                }else{
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
                        //b.writeLog("outdate："+outdate+"最终当天结果:"+value.get(outdate));
                    } else if (result7) {
                        if (isNumber > 0) {
                            //当天有打卡记录
                            //请假开始时间小于11:45,请假结束时间小于13:00
                            List<String> oldSignOutList = new ArrayList<String>();//定义上午签退数据
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                if (signTime.endsWith("2") && signForHour < 12) {
                                    oldSignOutList.add(signTime);
                                }
                            }
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取上午最后一条签退数据
                            endTime = (endTimeForHours * 60 + endTimeForMinutes) > 11 * 60 + 45 ? ("11:45:00:" + leaveoutFlag) : endTime;
                            //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                            if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.set(gooutStartDate.indexOf(signOutTime), startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                        //b.writeLog("当前请假日期："+outdate+";当天打卡数据集合（含打卡）:"+value.get(outdate));
                    } else if (result8) {
                        if (isNumber > 0) {
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
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次上午签退时间
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//取第一次下午签到时间
                            //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime);
                            //b.writeLog("下午签到时间:"+signInTime+"请假结束时间:"+endTime);
                            //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                            if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.set(gooutStartDate.indexOf(signOutTime), startTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                            }
                            //b.writeLog("请假开始时间与签退相比:"+gooutStartDate);
                            if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                                //b.writeLog("endTime:--------"+endTime);
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                            } else {
                                gooutStartDate.add(endTime);
                            }
                            //b.writeLog("请假结束时间与签到相比:"+gooutStartDate);
                            //b.writeLog("当天日期为："+outdate+"打卡集合为："+gooutStartDate);
                            value.put(outdate, gooutStartDate);
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            gooutStartDate.add("11:45:00:" + leaveoutFlag);
                            gooutStartDate.add("13:00:00:" + leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }
                    } else if (result9) {
                        if (isNumber > 0) {
                            //外出开始时间小于11:45,外出结束时间大于等于17:15
                            List<String> oldSignOutList = new ArrayList<String>();
                            //上午签退时间与开始时间比较
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                if (signTime.endsWith("2") && signForHour < 12) {
                                    oldSignOutList.add(signTime);
                                }
                            }
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次上午签退时间
                            //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                            //b.writeLog("上午签退时间:"+signOutTime+"请假开始时间:"+startTime+";两者比较:"+signOutTime.compareTo(startTime));
                            if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.set(gooutStartDate.indexOf(signOutTime), startTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                gooutStartDate.add("11:45:00:" + leaveoutFlag);
                                gooutStartDate.add("13:00:00:" + leaveinFlag);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            //当天无打卡记录
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            gooutStartDate.add("11:45:00:" + leaveoutFlag);
                            gooutStartDate.add("13:00:00:" + leaveinFlag);
                            value.put(outdate, gooutStartDate);
                        }
                        //b.writeLog("result9:"+result9+";当天日期:"+outdate+"当天打卡记录:"+gooutStartDate);
                    } else if (result11) {
                        startTime = "13:00:00:3";
                        if (isNumber > 0) {
                            //开始时间小于13:00,结束时间小于17:15
                            List<String> oldSignInList = new ArrayList<String>();
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                if (signTime.endsWith("1") && signForHour >= 12) {
                                    oldSignInList.add(signTime);
                                }
                            }
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//取第一次下午签到时间
                            //下午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                            if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                                gooutStartDate.add(startTime);
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
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
                    } else if (result13) {
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
                                String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签到时间
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
                        endTime = "17:15:00:" + leaveoutFlag;
                        if (isNumber > 0) {
                            //外出开始时间小于17:15,外出结束时间大于等于17:15
                            List<String> oldSignOutList = new ArrayList<String>();
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                int signForMin = Integer.parseInt(signTime.substring(3, 5));//打卡时间对应的分钟数
                                //修复下午请假 17：15之后还有打卡记录 2020.10.14
                                if ((signTime.endsWith("2")||signTime.endsWith("4")||signTime.endsWith("6")) && signForHour >= 12 && (signForHour*60+signForMin)<=1035) {
                                    oldSignOutList.add(signTime);
                                }
                            }
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次下午签退时间
                            //下午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                            if (signOutTime.compareTo(startTime) >= 0 && !signOutTime.equals("")) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.set(gooutStartDate.indexOf(signOutTime), startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
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
                public static void changeSaturdayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate, String leaveinFlag, String leaveoutFlag) {
                    //周六当天的打卡记录集合
                    List<String> gooutStartDate = new LinkedList<String>();
                    //如果打卡集合中包含当天打卡记录 则获取当天打卡数据
                    if (value.containsKey(outdate)) {
                        gooutStartDate = value.get(outdate);
                        Collections.sort(gooutStartDate);
                    }
                    int isNumber = gooutStartDate.size();//集合是否为空
                    int startTimeForMinutes = getTimeMin(startTime);//开始时间对应的分钟数
                    int endTimeForMinutes = getTimeMin(endTime);//结束时间对应的分钟数
                    //修改zcc 2020.06.20 ---start---
                    startTime = startTime + ":00:" + leaveinFlag;//将请假开始时间变成打卡签到时间
                    startTime = startTime.compareTo("08:30:00:" + leaveinFlag) <= 0 ? ("08:30:00:" + leaveinFlag) : startTime;
                    endTime = endTime + ":00:" + leaveoutFlag;//将请假结束时间变成打卡签退时间
                    endTime = endTime.compareTo("11:45:00:" + leaveoutFlag) >= 0 ? ("11:45:00:" + leaveoutFlag) : endTime;

                    //---end---
                    //1.外出开始时间小于等于8:30,外出结束时间小于11:45
                    boolean result1 = startTimeForMinutes <= (8 * 60 + 30) && endTimeForMinutes < (11 * 60 + 45);
                    //2.外出开始时间小于等于8:30,外出时间大于等于11:15
                    boolean result2 = startTimeForMinutes <= (8 * 60 + 30) && endTimeForMinutes >= (11 * 60 + 45);
                    //3.外出开始时间小于11：45,结束时间小于11：45
                    boolean result3 = startTimeForMinutes > (8 * 60 + 30) && startTimeForMinutes < (11 * 60 + 45) && endTimeForMinutes > (8 * 60 + 30) && endTimeForMinutes < (11 * 60 + 45);
                    //4.外出开始时间小于11:45,外出结束时间大于等于11:45
                    boolean result4 = startTimeForMinutes > (8 * 60 + 30) && startTimeForMinutes < (11 * 60 + 45) && endTimeForMinutes >= (11 * 60 + 45);

                    //外出当天打卡记录
                    if (result1) {
                        if (isNumber > 0) {
                            //请假开始时间小于等于8:30,请假结束时间小于11:45
                            List<String> oldSignInList = new ArrayList<String>();//定义签到时间
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                //取出请假当天上午签到数据
                                if (signTime.endsWith("1") && signForHour < 12) {
                                    oldSignInList.add(signTime);
                                }
                            }
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//有打卡时间则取第一次签到时间 否则赋值为空
                            //上午签到时间与请假结束时间比较 签到时间<=请假结束时间 将标准数据补上 否则默认为原打卡数据
                            if (signInTime.compareTo(endTime) <= 0) {
                                gooutStartDate.add(startTime);
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                    } else if (result2) {
                        gooutStartDate.add("08:30:00:" + leaveinFlag);
                        gooutStartDate.add("11:45:00:" + leaveoutFlag);
                        value.put(outdate, gooutStartDate);
                    } else if (result3) {
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
                        if (isNumber > 0) {
                            //外出开始时间小于11:45,外出结束时间大于等于11:45
                            List<String> oldSignOutList = new ArrayList<String>();//定义上午签退数据
                            for (String signTime : gooutStartDate) {
                                int signForHour = Integer.parseInt(signTime.substring(0, 2));//打卡时间对应的小时数
                                if (signTime.endsWith("2") && signForHour < 12) {
                                    oldSignOutList.add(signTime);
                                }
                            }
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取上午最后一条签退数据
                            //上午签退时间与请假开始时间比较 签退时间>=请假开始时间 将标准数据补上 否则默认为原打卡数据
                            if (signOutTime.compareTo(startTime) >= 0) {
                                startTime = startTime.substring(0, 9) + "1";
                                gooutStartDate.set(gooutStartDate.indexOf(signOutTime), startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            } else {
                                gooutStartDate.add(startTime);
                                gooutStartDate.add(endTime);
                                value.put(outdate, gooutStartDate);
                            }
                        } else {
                            gooutStartDate.add(startTime);
                            gooutStartDate.add(endTime);
                            value.put(outdate, gooutStartDate);
                        }
                    }
                }
            %>
    <!--计算周一至周五迟到早退旷工时间-->
    <%!
        public static void computeDailyLateAndEarlyTime(List<String> finalTimeList, Double count, Double lateTime, Double earlyTime) {
            /**
             *迟到早退旷工计算规则
             * 打卡记录为 0或1次打卡记录 算旷工一天
             * 打卡记录为 2次打卡记录 上午签到
             */
            int collectionSize = finalTimeList.size();//打卡时间集合大小
            //判断是否有加班时间 如果有下午加班时间 设置新的集合长度
            for (String time : finalTimeList) {
                int min = Integer.parseInt(time.substring(0, 2)) * 60 + Integer.parseInt(time.substring(3, 5));
                int index = 0;
                if (time.endsWith("2") && min > 12 * 60) {
                    index++;
                }
                if (index > 1) {
                    collectionSize = collectionSize - index + 1;
                }
            }
            ////b.writeLog("最新集合:"+collectionSize);
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
                String time1 = finalTimeList.get(0);
                String time2 = finalTimeList.get(1);
                int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                int result1 = time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("2") && min2 < 12 * 60 ? 1 : 0;
                int result2 = ((time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("1") && min2 >= 12 * 60) || (time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("2") && min2 > 12 * 60) ||
                        (time1.endsWith("2") && min1 < 12 * 60 && time2.endsWith("1") && min2 >= 12 * 60) || (time1.endsWith("2") && min1 < 12 * 60 && time2.endsWith("2") && min2 > 12 * 60)) ? 1 : 0;
                int result3 = time1.endsWith("1") && min1 >= 12 * 60 && time2.endsWith("2") && min2 >= 12 * 60 ? 1 : 0;
                if (result1 == 1) {
                    if (min1 >= 9 * 60 || min2 <= 11 * 60 + 15) {
                        count++;
                    } else {
                        if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                            lateTime += min1 - 8 * 60 - 30;
                        }
                        if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                            earlyTime += 11 * 60 + 45 - min2;
                        }
                        count += 0.5;
                    }
                }
                if (result2 == 1) {
                    count++;
                }
                if (result3 == 1) {
                    if (min1 >= 13 * 60 + 45 || min2 <= 16 * 60 + 45) {
                        count++;
                    } else {
                        if (min1 > 13 * 60 + 15 && min1 < 13 * 60 + 45) {
                            lateTime += min1 - 13 * 60 - 15;
                        }
                        if (min2 > 16 * 60 + 45 && min2 < 17 * 60 + 15) {
                            earlyTime += 17 * 60 + 15 - min2;
                        }
                        count += 0.5;
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
                String time1 = finalTimeList.get(0);
                String time2 = finalTimeList.get(1);
                String time3 = finalTimeList.get(2);
                int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                int min3 = Integer.parseInt(time3.substring(0, 2)) * 60 + Integer.parseInt(time3.substring(3, 5));
                int result1 = ((time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("2") && min2 < 12 * 60 && time1.endsWith("1") && min3 >= 12 * 60) ||
                        (time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("2") && min2 < 12 * 60 && time1.endsWith("2") && min3 >= 12 * 60)) ? 1 : 0;
                int result2 = ((time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("1") && min2 >= 12 * 60 && time1.endsWith("2") && min3 >= 12 * 60) ||
                        (time1.endsWith("2") && min1 < 12 * 60 && time2.endsWith("1") && min2 >= 12 * 60 && time1.endsWith("2") && min3 >= 12 * 60)) ? 1 : 0;
                if (result1 == 1) {
                    if (min1 >= 9 * 60 || min2 <= 11 * 60 + 15) {
                        count++;
                    } else {
                        if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                            lateTime += min1 - 8 * 60 - 30;
                        }
                        if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                            earlyTime += 11 * 60 + 45 - min2;
                        }
                        count += 0.5;
                    }
                }
                if (result2 == 1) {
                    if (min2 >= 13 * 60 + 45 || min3 <= 16 * 60 + 45) {
                        count++;
                    } else {
                        if (min2 > 13 * 60 + 15 && min2 < 13 * 60 + 45) {
                            lateTime += min2 - 13 * 60 - 15;
                        }
                        if (min3 > 16 * 60 + 45 && min3 < 17 * 60 + 15) {
                            earlyTime += 17 * 60 + 15 - min3;
                        }
                        count += 0.5;
                    }
                }
            } else if (collectionSize == 4) {
                String time1 = finalTimeList.get(0);
                String time2 = finalTimeList.get(1);
                String time3 = finalTimeList.get(2);
                String time4 = finalTimeList.get(3);
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
                if (min3 > 13 * 60 + 15 && min3 < 13 * 60 + 45) {
                    lateTime += min3 - 13 * 60 - 15;
                }
                if (min4 > 16 * 60 + 45 && min4 < 17 * 60 + 15) {
                    earlyTime += 17 * 60 + 15 - min4;
                }
                /**
                 * 打卡记录有3次及以上超过规定时间的半个小时
                 */
                if ((min1 >= 9 * 60 && min2 <= 11 * 60 + 15) || (min3 >= 13 * 60 + 45 && min4 <= 16 * 60 + 45)) {
                    if ((min1 >= 9 * 60 || min2 <= 11 * 50 + 15)) {
                        if (min3 > 13 * 60 + 15 && min3 < 13 * 60 + 45) {
                            lateTime += min3 - 13 * 60 - 15;
                        }
                        if (min4 > 16 * 60 + 45 && min4 < 17 * 60 + 15) {
                            earlyTime += 17 * 60 + 15 - min4;
                        }
                    }
                    if (min3 >= 13 * 60 + 45 || min4 <= 16 * 60 + 45) {
                        if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                            lateTime += min1 - 8 * 60 - 30;
                        }
                        if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                            earlyTime += 11 * 60 + 45 - min2;
                        }
                    }
                    count += 0.5;
                } else if ((min1 >= 9 * 60 && min3 >= 13 * 60 + 45) || (min1 >= 9 * 60 && min4 <= 16 * 60 + 45) ||
                        (min2 <= 11 * 50 + 15 && min3 >= 13 * 60 + 45) || (min2 <= 11 * 60 + 15 && min4 <= 16 * 60 + 45)) {
                    count++;
                } else {
                    if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                        lateTime += min1 - 8 * 60 - 30;
                    } else if (min1 >= 9 * 60) {
                        count += 0.5;
                    }
                    if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                        earlyTime += 11 * 60 + 45 - min2;
                    } else if (min2 <= 11 * 60 + 15) {
                        count += 0.5;
                    }
                    if (min3 > 13 * 60 + 15 && min3 < 13 * 60 + 45) {
                        lateTime += min3 - 13 * 60 - 15;
                    } else if (min3 >= 13 * 60 + 45) {
                        count += 0.5;
                    }
                    if (min4 > 16 * 60 + 45 && min4 < 17 * 60 + 15) {
                        earlyTime += 17 * 60 + 15 - min4;
                    } else if (min4 <= 16 * 60 + 45) {
                        count += 0.5;
                    }
                }
            }
            BaseBean b = new BaseBean();
            ////b.writeLog(count+';'+lateTime+";"+earlyTime);
        }
    %>
    <!--计算周六迟到早退旷工时间-->
    <%!
        public static void computeSaturdayLateAndEarlyTime(List<String> finalTimeList, Double count, Double lateTime, Double earlyTime) {
            if (finalTimeList.size() <= 1) {
                count += 0.5;
            } else if (finalTimeList.size() == 2) {
                String time1 = finalTimeList.get(0);
                String time2 = finalTimeList.get(1);
                int min1 = Integer.parseInt(time1.substring(0, 2)) * 60 + Integer.parseInt(time1.substring(3, 5));
                int min2 = Integer.parseInt(time2.substring(0, 2)) * 60 + Integer.parseInt(time2.substring(3, 5));
                int result1 = time1.endsWith("1") && min1 < 12 * 60 && time2.endsWith("2") && min2 < 12 * 60 ? 1 : 0;
                if (result1 == 1) {
                    if (min1 >= 9 * 60 || min2 <= 11 * 60 + 15) {
                        count++;
                    } else {
                        if (min1 > 8 * 60 + 30 && min1 < 9 * 60) {
                            lateTime += min1 - 8 * 60 - 30;
                        }
                        if (min2 > 11 * 60 + 15 && min2 < 11 * 60 + 45) {
                            earlyTime += 11 * 60 + 45 - min2;
                        }
                        count += 0.5;
                    }
                }
            }
        }
    %>
    <!--查询出截止请假日期当天的请假数据-->
    <%!
        public static Double getHour(String endDate, String endTime) {
            double cnt8 = 0.0;
            String endDateSql = "select attendancestatus from uf_attendance where curdate='" + endDate + "'  ";
            RecordSet recordSet2 = new RecordSet();
            recordSet2.execute(endDateSql);
            while (recordSet2.next()) {
                int attendancestatus = recordSet2.getInt(1);

                int endMin = Integer.parseInt(endTime.substring(0, 2)) * 60 + Integer.parseInt(endTime.substring(3, 5));
                if (attendancestatus == 0) {
                    if (endMin >= 8 * 60 + 30 && endMin < 11 * 60 + 45) {
                        cnt8 += (endMin - 8 * 60 - 30) / 60;
                    } else if (endMin >= 11 * 60 + 45 && endMin <= 13 * 60 + 15) {
                        cnt8 += 3.25;
                    } else if (endMin > 13 * 60 + 15 && endMin < 17 * 60 + 15) {
                        cnt8 += (endMin - 8 * 60 - 30 - 90) / 60;
                    } else if (endMin >= 17 * 60 + 15) {
                        cnt8 += 7.25;
                    }
                } else if (attendancestatus== 2) {
                    if (endMin >= 8 * 60 + 30 && endMin < 11 * 60 + 45) {
                        cnt8 += (endMin - 8 * 60 - 30) / 60;
                    } else if (endMin >= 11 * 60 + 45) {
                        cnt8 += 3.25;
                    }
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
            String time1 = ((hour + 1) <= 9 ? ("0" + String.valueOf(hour + 1)) : (String.valueOf(hour + 1))) + ":" +
                    ((minute - 30 <= 9) ? ("0" + String.valueOf(minute - 30)) : (String.valueOf(minute - 30))) + time.substring(5);
            String time2 = ((hour) <= 9 ? ("0" + String.valueOf(hour)) : (String.valueOf(hour))) + ":" +
                    ((minute + 30 <= 9) ? ("0" + String.valueOf(minute + 30)) : (String.valueOf(minute + 30))) + time.substring(5);
            return minute >= 30 ? time1 : time2;
        }
    %>
    <!--获取半小时前的时间-->
    <%!
        public static String getBeforeHalfHour(String curTime) {
            int hour1 = Integer.parseInt(curTime.substring(0, 2));
            int minute1 = Integer.parseInt(curTime.substring(3, 5));
            String time3 = ((hour1) <= 9 ? ("0" + String.valueOf(hour1)) : (String.valueOf(hour1))) + ":" +
                    ((minute1 - 30 <= 9) ? ("0" + String.valueOf(minute1 - 30)) : (String.valueOf(minute1 - 30))) + curTime.substring(5);
            String time4 = ((hour1 - 1) <= 9 ? ("0" + String.valueOf(hour1 - 1)) : (String.valueOf(hour1 - 1))) + ":" +
                    ((minute1 + 30 <= 9) ? ("0" + String.valueOf(minute1 + 30)) : (String.valueOf(minute1 + 30))) + curTime.substring(5);
            return minute1 >= 30 ? time3 : time4;
        }
    %>
    <!--对哺乳假数据进行处理-->
    <%!
        public static List<String> reviseFinalTimeList(List<String> finalTimeList, String curdate, String id) {
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
                                time = (Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2);
                                time = time.compareTo("08:30:00:1") >= 0 ? time : "08:30:00:1";//修正后的时间如果小于08：30，则取08：30
                            }
                        }
                        //上午签退早1小时
                        if (result2) {
                            //取出上午签退时间
                            if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) < 12)) {
                                time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
                                time = time.compareTo("11:45:00:2") <= 0 ? time : "11:45:00:2";//修正后的时间如果大于11:45，则取11:45
                            }
                        }
                        //下午签到晚1小时
                        if (result3) {
                            //取出下午签退时间
                            if (time.endsWith("1") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                time = ((Integer.parseInt(time.substring(0, 2)) - 1) <= 9 ? ("0" + String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) - 1))) + time.substring(2);
                                time = time.compareTo("13:00:00:1") >= 0 ? time : "13:00:00:1";//修正后的时间如果大于13:00，则取13:00
                            }
                        }
                        //下午签退早1小时
                        if (result4) {
                            //取出下午签退时间
                            if (time.endsWith("2") && (Integer.parseInt(time.substring(0, 2)) >= 12)) {
                                time = ((Integer.parseInt(time.substring(0, 2)) + 1) <= 9 ? ("0" + String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1)) + time.substring(2) : (String.valueOf(Integer.parseInt(time.substring(0, 2)) + 1))) + time.substring(2);
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
            if (newFinalTimeList.size() == 0) {
                newFinalTimeList = finalTimeList;
            }
            return newFinalTimeList;
        }
    %>
    <!--查询单结果为string对应的名称-->
    <%!
        public static String getName(String sql){
            RecordSet recordSet = new RecordSet();
            recordSet.execute(sql);
            recordSet.next();
            return recordSet.getString(1);
        }
    %>
    <!--查询单结果为int对应的名称-->
    <%!
        public static int getId(String getCompanyIdSql, String DateSource) throws Exception {
            RecordSet recordSet = new RecordSet();
            recordSet.executeSql(getCompanyIdSql, DateSource);
            recordSet.next();
            int companyId = recordSet.getInt(1);
            return companyId;
        }
    %>
    <!--查询单结果为int对应的名称1-->
    <%!
        public static int getId1(String getCompanyIdSql){
            RecordSet recordSet = new RecordSet();
            recordSet.execute(getCompanyIdSql);
            recordSet.next();
            return recordSet.getInt(1);
        }
    %>
    <!--查询单结果为double对应的名称-->
    <%!
        public static double getDoubleNumber(String getCompanyIdSql){
            RecordSet recordSet = new RecordSet();
            recordSet.execute(getCompanyIdSql);
            recordSet.next();
            return recordSet.getDouble(1);
        }
    %>
    <!--将时间转换成int类型-->
    <%!
        public static int getTimeMin(String curTime, int index) {
            return Integer.parseInt(curTime.split(":")[index]);
        }
    %>
    <!--时间戳换算-->
    <%!
        public int timeStampConversion(String signtime) {
            int signintTime = 0;
            try {
                if (signtime != null && !signtime.equals("")) {
                    signintTime = Integer.parseInt(signtime.substring(0, 2)) * 60 + Integer.parseInt(signtime.substring(3, 5)); //开始时间戳
                    ////b.writeLog("signintTime："+signintTime);
                }
            } catch (Exception e) {
                e.getLocalizedMessage();
            }
            return signintTime;
        }

        ;
    %>
    <%!
        /**
         * 查询出开始日期到结束日期包含的日期(包含开始日期和结束日期)
         * @param stime
         * @param etime
         * @return ArrayList<String>
         */
        public static ArrayList<String> findDates(String stime, String etime) {
            ArrayList<String> allDate = new ArrayList<String>();
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
            Date dBegin;
            try {
                dBegin = sdf.parse(stime);
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
            } catch (ParseException e) {
                e.printStackTrace();
            }
            return allDate;
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
			return Integer.parseInt(curTime.split(":")[0]) * 60 + Integer.parseInt(curTime.split(":")[1]);
		}
	%>
</table>
</body>
</html>
