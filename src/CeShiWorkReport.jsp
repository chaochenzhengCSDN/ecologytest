<!-- 门店考勤月报表 -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="com.weaver.general.Util" %>
<%@page import="weaver.conn.RecordSet" %>
<%@ page import="weaver.iiot.grouptow.common.*" %>
<%@ page import="weaver.iiot.grouptow.common.entity.CurdayContion" %>
<%@ page import="java.text.DecimalFormat" %>
<%@ page import="java.text.ParseException" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="weaver.iiot.grouptow.util.AttendanceUtil" %>
<%@ page import="com.qiyuesuo.pdf.text.pdf.parser.A" %>
<jsp:useBean id="BaseBean" class="weaver.general.BaseBean"/>
<jsp:useBean id="ResourceComInfo" class="weaver.hrm.resource.ResourceComInfo"/>
<%

    BaseBean b = new BaseBean();
    String abnoralName = "formtable_main_1033";
    String abnoralName1 = "formtable_main_1125";
    b.writeLog("当前用户:" + user.getLastname() + "----" + user.getUID());
    DecimalFormat df11 = new DecimalFormat("0.00");//设置保留位数
    String month = Util.null2String(request.getParameter("month"));

    //获取人员名称
    String userid = Util.null2String(request.getParameter("staffName"));
    //b.writeLog("查询用户:" + userid);

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
    String curdate1 = year2 + "-" + month2;
    String ysdate = curdate1 + "-01";
    String yedate = curdate1 + "-31";
    c.add(Calendar.MONTH, -1);
    c.add(Calendar.MONTH, 2);

%>

<head>
    <style type="text/css">
        #div1 td {
            padding-top: 10px;
            padding-bottom: 10px;
            width: 100px;
        }

        #div1 {
            overflow: auto;
            width: 100%;
            height: calc(100vh - 170px);
        }
    </style>
</head>
<body>
<div id="div1">
    <table width="100%" border="0" cellpadding="0" cellspacing="0">
        <tr id="trr1">
            <td align='center' rowspan=2><b>公司</b></td>
            <td align='center' rowspan=2><b>部门</b></td>
            <td align='center' rowspan=2><b>姓名</b></td>
            <td align='center' rowspan=2><b>月份</b></td>
            <td align='center' rowspan=2><b>应出勤（天）</b></td>
            <td align='center' rowspan=2><b>基本工时</b></td>
            <td align='center' rowspan=2><b>实出勤（天）</b></td>
            <td align='center' rowspan=2><b>实际工时</b></td>
            <td align='center' rowspan=2><b>法定节假日</b></td>
            <td align='center' rowspan=2><b>迟到（分）</b></td>
            <td align='center' rowspan=2><b>早退（分）</b></td>
            <td align='center' rowspan=2><b>旷工（小时）</b></td>
            <td align='center' rowspan=2><b>异常流程次数</b></td>
            <td align='center' colspan=3><b>请假（小时）</b></td>
            <td align='center' colspan=3><b>加班（小时）</b></td>
            <td align='center' rowspan=2><b>剩余调休时间（小时）</b></td>
            <td align='center' colspan=3><b>年假</b></td>
        </tr>
        <tr id="trr2">
            <td align='center'><b>调休</b></td>
            <td align='center'><b>年休假</b></td>
            <td align='center'><b>事假</b></td>
            <td align='center'><b>加班工时</b></td>
            <td align='center'><b>加点工时</b></td>
            <td align='center'><b>调休工时</b></td>
            <td align='center'><b>总共</b></td>
            <td align='center'><b>已用</b></td>
            <td align='center'><b>可用</b></td>
        </tr>
            <%
            LeaveCommonController leaveCommonController = new LeaveCommonController();
            AbnormalCommonController abnormalCommonController = new AbnormalCommonController();
            BusinessCommonController businessCommonController = new BusinessCommonController();
            CurdayContionController curdayContionController = new CurdayContionController();
            FinalTimeListController finalTimeListController = new FinalTimeListController();
            AttendanceUtil attendanceUtil = new AttendanceUtil();
            String curDay=curDate1.substring(8);
            //比较当前月份的上一个月以及查询月份
            int lastMonth=(Integer.parseInt(curDay)<=12)?(Integer.parseInt(curDate1.substring(5,7))-2):(Integer.parseInt(curDate1.substring(5,7))-1);
            String lastmonth=lastMonth>=10?String.valueOf(lastMonth):("0"+ lastMonth);
			lastmonth = year2 +"-"+ lastmonth;

            //查询条件不为空时，可以查询
            if(month !=null&&!month.isEmpty()&&userid !=null&&!userid.isEmpty()){
            //当月日期在13号之后(包含13号)，可查询上个月考勤明细
            boolean compareResult=true;
            if(compareResult&&month.compareTo("2020-09")>=0){

            String selectSql1 = "select nvl(count(*),0) from uf_attendance where attendancestatus like '0%'  and CURDATE like '%" + month + "%'  ";
            int cnt2 = attendanceUtil.getId(selectSql1); //整天都出勤的天数
            b.writeLog("查询整天出勤天数的语句:"+selectSql1+"查询结果为:"+cnt2);

            String selectSql2 = "select nvl(count(*),0) from uf_attendance where attendancestatus like '2%' and CURDATE like '%" + month + "%'  ";
            int cnt3 = attendanceUtil.getId(selectSql2);//上午半天出勤的天数
            b.writeLog("查询单休周六天数的语句:"+selectSql2+"查询结果为:"+cnt3);

			String selectSql3 = "select nvl(count(*),0) from uf_attendance where ISHOLIDAY=0 and CURDATE like '%" + month + "%'  ";
			int cnt4 = attendanceUtil.getId(selectSql3);//节假日天数
			b.writeLog("查询节假日天数的语句:"+selectSql3+"查询结果为:"+cnt4);

            double dueDays= cnt2 + cnt3;//应出勤天数
            double basicWorkTime = (cnt2 * 7.5 + cnt3 * 6.5*2+ cnt4*7.5); //基本工时
			if(month.equals("2020-10")){
				basicWorkTime +=3.25;
			}

            //处理合同开始时间在当月或合同结束时间在当月
            String startDateSql="select startdate from hrmresource where id='"+userid+"'";
            String contractStartDate= attendanceUtil.getName(startDateSql);
            //如果合同开始时间为空，则赋值为2000-01-01
            contractStartDate =(contractStartDate==null||contractStartDate.isEmpty())?"2000-01-01":contractStartDate;
            b.writeLog("查询合同开始日期的语句:"+startDateSql+"查询结果为:"+contractStartDate);

            String endDateSql="select enddate from hrmresource where id='"+userid+"'";
            String contractEndDate= attendanceUtil.getName(endDateSql);
            //如果合同开始结束为空，则赋值为2100-01-01
            contractEndDate =(contractEndDate==null||contractEndDate.isEmpty())?"2100-01-01":contractEndDate;
             b.writeLog("查询合同结束日期的语句:"+endDateSql+"查询结果为:"+contractEndDate);

            List<String> curdateList = attendanceUtil.getCurdateList(month,0,contractStartDate,contractEndDate);//出勤整天的集合

			List<String> saturdayList= attendanceUtil.getCurdateList(month,2,contractStartDate,contractEndDate);//出勤单休周六的集合

            
            String sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname," +
            "hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType,hre.id,(SELECT COUNT( isholiday ) FROM uf_attendance WHERE" +
            " curdate BETWEEN '"+ysdate+"' AND '"+yedate+"' AND isholiday = 0) AS holiday FROM hrmresource hre LEFT JOIN hrmschedulesign hsc " +
            "ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN " +
            "hrmdepartment hde ON hre.departmentid=hde.id WHERE hre.accounttype !=1 and hre.id= '"+userid+"' AND CASE WHEN hre.startdate is NULL " +
            "THEN '"+checkMaxDate+"' ELSE hre.startdate END <= '"+checkMaxDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+checkMinDate+"' ELSE " +
            "hre.enddate END >= '"+checkMinDate+"' ORDER BY hde.id,hsc.signDate ASC";
            b.writeLog("sql语句："+sql);
            //定义集合，把数据进行封装
            Map<String,Map<String,List<String>>> areaResult = attendanceUtil.getAreaResult(sql);
            //判断获取的数据是否为空
            if(areaResult!=null && areaResult.size()>0){
                //获取结果集所有键的集合，用keySet()方法实现
                Set<String> keySet = areaResult.keySet();
                double countHours=0.0;//旷工小时数
                double earlyTime = 0.0;//记录早退分钟数
                double lateTime = 0.0;//记录迟到分钟数
                //遍历键的集合，获取到每一个键。用增强for实现
                for (String key : keySet) {
                    String subcompanyname = key.split(",")[0];
                    String departmentname = key.split(",")[1];
                    String workCode = key.split(",")[2];
                    String lastname = key.split(",")[3];
                    String id = key.split(",")[4];
                    String holiday = key.split(",")[5];
                    out.println("<tr>");
                    out.println("<td align='center'>" + subcompanyname + "</td>");//公司
                    out.println("<td align='center'>" + departmentname + "</td>");//部门
                    out.println("<td align='center'>" + lastname + "</td>");//姓名
                    out.println("<td align='center'>" + month + "</td>");//月份
                    out.println("<td align='center'>" + dueDays + "</td>");//应出勤 周一到周五*1 + 周六*0.5
                    out.println("<td align='center'>" + basicWorkTime + "</td>");//基本工时

                    //根据键去找值，用get(Object key)方法实现
                    Map<String, List<String>> value = areaResult.get(key);
                    businessCommonController.changeBusinessTripTime(value,checkMinDate,checkMaxDate,id,month,"1","2");
                    //调用方法，改变异常考勤时的打卡时间
                    abnormalCommonController.changeAbnormalSignTime(value,id,month);
                    double actualDays = 0.0;//实际天数
                    double actualWorkingHours = 0.0;//实际工时

                    actualDays = curdayContionController.getActualDays(value,b,curdateList,saturdayList,id).getActualWorkingDay();

                    //b.writeLog("实际天数:"+actualDays);
                    out.println("<td align='center'>" + actualDays + "</td>");//实出勤

                     //调用方法，改变请假(调休)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,8,"3","4");
                    //调用方法，改变请假(年假)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,0,"3","4");
                    //调用方法，改变请假(事假)的打卡时间
                    leaveCommonController.changeLeaveTime(value, id,likeDate,9,"5","6");
                    //判断value集合是否为空
                    //b.writeLog("打卡最终信息:" + value);
                    if (value.size() > 0) {
                        //获取结果集所有键的集合，用keySet()方法实现
                        Set<String> valueSet = value.keySet();
                        //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
                        TreeSet<String> ts1 = attendanceUtil.getDateTreeSet();
                        ts1.addAll(valueSet);
                        //遍历键的集合，获取到每一个键。用增强for实现
                        Map<String,List<String>> map1=new TreeMap<String, List<String>>();
                        for (String key1 : ts1) {
                            if (Integer.parseInt(key1.split("-")[1]) == Integer.parseInt(month.split("-")[1])) {
                                //根据键去找值，用get(Object key)方法实现
                                List<String> timeList = value.get(key1);
                                Collections.sort(timeList);
                                List<String> finalTimeList = finalTimeListController.getFinalTimeList(timeList);
                                //对哺乳假数据进行处理
								List<String> newFinalTimeList = finalTimeListController.reviseFinalTimeList(finalTimeList,key1,id);

                                map1.put(key1,newFinalTimeList);
                            }
                        }
                        //b.writeLog("最终map集合:"+map1);
                        List<CurdayContion> curdayContions = curdayContionController.getCurdayContions(map1,curdateList,saturdayList,b,id,likeDate);
                        for(CurdayContion curdayContion:curdayContions){
                            b.writeLog("当天日期:"+curdayContion.getCurDate()+";当天矿工小时数:"+curdayContion.getCountHours());
                            b.writeLog("当天迟到小时数:"+curdayContion.getLateTime()+";当天早退小时数:"+curdayContion.getEarlyTime());
                            countHours += curdayContion.getCountHours();
                            lateTime += curdayContion.getLateTime();
                            earlyTime += curdayContion.getEarlyTime();
                            actualWorkingHours += curdayContion.getActualWorkingHours();
                        }
						actualWorkingHours += cnt4*7.5;
						if(month.equals("2020-10")){
							actualWorkingHours += 3.25;
						}
                        //b.writeLog("周一至周五总天数:"+curdateList+";周六总勤天数:"+saturdayList);
                        out.println("<td align='center'>" + String.format("%.2f", actualWorkingHours) + "</td>");//实际工时
                        out.println("<td align='center'>" + holiday + "</td>");//节假日
                        out.println("<td align='center'>" + lateTime + "</td>");//迟到分钟数
                        out.println("<td align='center'>" + earlyTime + "</td>");//早退分钟数
                        out.println("<td align='center'>" + countHours + "</td>");//旷工小时数
                    }else{
                        //当月没有打卡记录
                        out.println("<td align='center'>" + 0 + "</td>");//实际工时
                        out.println("<td align='center'>" + holiday + "</td>");//节假日
                        out.println("<td align='center'>" + 0 + "</td>");//迟到分钟数
                        out.println("<td align='center'>" + 0 + "</td>");//早退分钟数
                        out.println("<td align='center'>" + basicWorkTime + "</td>");//旷工天数
                    }
                        //异常流程次数
                        String abnormalTimeSql = "select nvl(sum(morning_sign_in),0)+nvl(sum(afternoon_sign_in),0)+nvl(sum(morning_sign_back),0)+nvl(sum(afternoon_sign_back),0) from "+abnoralName+" where abnormal_date like '%" + month + "%' and userid='"+userid+"' ";
                        int cnt5=attendanceUtil.getId(abnormalTimeSql);
                        //b.writeLog("异常流程次数："+abnormalTimeSql);
                        out.println("<td align='center'>" + cnt5 + "</td>");//异常流程次数
                        //请假数据获取 获取当月的请假数据 获取上月底至本月初的请假数据 获取本月底至下月初的请假数据
                        for (Integer num1 : attendanceUtil.getLeaveStandard()) {
                            //获取当月的请假数据
                            String leaveSql = "select case when sum(hours) is null then 0.00 else sum(hours) end as 总天数 from uf_AskForLeave where userid='"+userid+"' and " +
                                    " type=" + num1 + " and start_date like '%" + month + "%' and end_date like '%" + month + "%' ";
                            //b.writeLog("当前请假sql语句:"+leaveSql);
                            RecordSet rs13 = new RecordSet();
                            rs13.execute(leaveSql);
                            Double cnt7  ;
                            rs13.next();
                            cnt7 = rs13.getDouble(1);
                            cnt7 += attendanceUtil.getLeaveTime(num1,month,workCode);
                            cnt7 += attendanceUtil.getLeaveTime1(num1,month,workCode);
                            out.println("<td align='center'>" + attendanceUtil.keepTwoDecimals(cnt7) + "</td>");
                        }
                        //加班工时
                        //获取该用户的薪资方式 0固薪 1时薪 固薪则加班工时为0 时薪则计算调休为否的加班时长
                        int type=attendanceUtil.getSalaryType(userid);
                        if(type==0){
                            out.println("<td align='center'>" + 0.00 + "</td>");//加班工时
                        }else if(type==1){
                            String addedHoursSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                    "WHERE WORK_DATE LIKE '%" + month + "%' AND userid='"+userid+"' and " +
                                    "WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where ATTENDANCESTATUS like (1,2))  and OVERTIME_TYPE in (1,3) and break_off=1 ";
                            RecordSet rs16 = new RecordSet();
                            rs16.execute(addedHoursSql);
                            //b.writeLog("加班工时sql:"+addedHoursSql);
                            rs16.next();
                            Double cnt9 = rs16.getDouble(1);
                            out.println("<td align='center'>" + attendanceUtil.keepTwoDecimals(cnt9) + "</td>");//加班工时
                        }
                        //加点工时
                        String OvertimebyHourSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                "WHERE WORK_DATE LIKE '%" + month + "%' AND userid='"+userid+"' AND " +
                                "(OVERTIME_TYPE IN (0,2) or (OVERTIME_TYPE in (3) and break_off=1 and WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where ATTENDANCESTATUS like '0%'))) ";
                        RecordSet rs15 = new RecordSet();
                        rs15.execute(OvertimebyHourSql);
                        //b.writeLog("加点工时sql:"+OvertimebyHourSql);
                        rs15.next();
                        Double cnt8 = rs15.getDouble(1);
                        out.println("<td align='center'>" + attendanceUtil.keepTwoDecimals(cnt8) + "</td>");//加点工时
                        //调休工时
                        String paidLeaveTimeSql  =  "SELECT nvl(SUM(overtime_hours),0.00) FROM uf_WorkOvertime WHERE break_off = 0 AND WORK_DATE LIKE '%" + month + "%' AND userid='"+userid+"'";
                        Double cnt11= attendanceUtil.getDoubleNumber(paidLeaveTimeSql);
                        out.println("<td align='center'>" + attendanceUtil.keepTwoDecimals(cnt11) + "</td>");//调休工时

                        //剩余调休时间
                        String spareLeaveSql = "select nvl(SUM (OVERTIME_HOURS),0.00) from uf_TimePoolB where userid='"+userid+"' and iseffective=0 ";
                        RecordSet rs10 = new RecordSet();
                        rs10.execute(spareLeaveSql);
                        //b.writeLog("剩余调休时间sql:" + spareLeaveSql);
                        rs10.next();
                        Double cnt6 = rs10.getDouble(1);
                        out.println("<td align='center'>" + attendanceUtil.keepTwoDecimals(cnt6) + "</td>");//剩余调休工时
                        //获取年假数据 总时长 已用时长 剩余时长
                        String annualInfoSql = "select total_days,used_days,DECODE(total_days-used_days,null,0,total_days-used_days) spareHours from uf_annual_info where userid='"+userid+"' and year='"+month.split("-")[0]+"' ";
                        RecordSet rs11 = new RecordSet();
                        rs11.execute(annualInfoSql);
                        //b.writeLog("年假数据sql:"+annualInfoSql);
                        double totalDays;
                        double usedDays;
                        double spareDays;
                        String totalDaysInfo;
                        String usedDaysInfo;
                        String spareDaysInfo;
                        if (rs11 != null && rs11.next()) {
                            //年假总共小时数
                            totalDays = rs11.getDouble(1);
                            //年假总共显示格式xx天
                            totalDaysInfo = totalDays + "天";
                            //年假已用小时数
                            usedDays= rs11.getDouble(2);
                            //年假已用显示格式xx天
                            usedDaysInfo = usedDays  + "天";
                            //年假可用小时数
                            spareDays = rs11.getDouble(3);
                            //年假可用显示格式xx天
                            spareDaysInfo= spareDays + "天";
                        } else {
                            totalDaysInfo="0.0天";
                            usedDaysInfo="0.0天";
                            spareDaysInfo="0.0天";
                        }
                        out.println("<td align='center'>" + totalDaysInfo + "</td>");//总共年假
                        out.println("<td align='center'>" + usedDaysInfo + "</td>");//已用年假
                        out.println("<td align='center'>" + spareDaysInfo + "</td>");//可用年假
                        out.println("</tr>");
        %>
        <table border="0" width="100%">
            <tbody>
            <tr>
                <td align="right"></td>
            </tr>
            <tr align="center" border="0">
                <td>
                    <a href="javascript:void(0);"
                       onclick="todo('/iiot/studytest/zzh/ceshi/WholeDetail.jsp?month=<%=month%>&userId=<%=id%>','总明细表')"
                       class="e8_btn_top_a">总明细表</a>&nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="javascript:void(0);"
                       onclick="todo('/iiot/studytest/zzh/ceshi/BusinessDetail.jsp?month=<%=month%>&userId=<%=id%>','出差明细')"
                       class="e8_btn_top_a">出差明细</a>&nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="javascript:void(0);"
                       onclick="todo('/iiot/studytest/zzh/ceshi/OverTimeDetail.jsp?month=<%=month%>&userId=<%=id%>','加班明细')"
                       class="e8_btn_top_a">加班明细</a>&nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="javascript:void(0);"
                       onclick="todo('/iiot/studytest/zzh/ceshi/AbsenteeismDetail.jsp?month=<%=month%>&userId=<%=id%>','旷工明细')"
                       class="e8_btn_top_a">旷工明细</a>&nbsp;&nbsp;|&nbsp;&nbsp;
                    <a href="javascript:void(0);"
                       onclick="todo('/iiot/studytest/zzh/ceshi/LeaveDetail.jsp?month=<%=month%>&userId=<%=id%>','请假明细')"
                       class="e8_btn_top_a">请假明细</a>
                </td>
            </tr>
            </tbody>

            <%
            }
                    } else {
                        //为空则输出无查询结果
                        out.println("<tr>");
                        out.println("<td style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center' colspan=25>无查询结果，请确认查询报表条件</td>");
                        out.println("</tr>");
                    }
                } else {
                    //无权限查询
                    out.println("<tr>");
                    out.println("<td style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center' colspan=25>当前用户无权限查询，请联系管理员</td>");
                    out.println("</tr>");
                }
                }else{
                    //非空校验
                    out.println("<tr>");
                    out.println("<td style='font-size:18px;height:80px;border: 1px solid #90BADD;' align='center' colspan=25>请填写搜索条件</td>");
                    out.println("</tr>");
                }
            %>

        </table>
</div>
</body>

