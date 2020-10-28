<!-- 门店考勤月报表 -->
<%@ page contentType="text/html; charset=UTF-8" %>
<%@page import="weaver.conn.RecordSet" %>
<%@page import="java.text.DecimalFormat" %>
<%@page import="java.text.ParseException" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%@ page import="com.weaver.general.Util" %>
<jsp:useBean id="ResourceComInfo" class="weaver.hrm.resource.ResourceComInfo"/>
<%

    DecimalFormat df11 = new DecimalFormat("0.00");//设置保留位数
    String month = Util.null2String(request.getParameter("month"));

    //获取人员名称
    String userid = Util.null2String(request.getParameter("staffName"));

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
            <td align='center'><b>加点工时</b></td>
            <td align='center'><b>加班工时</b></td>
            <td align='center'><b>调休工时</b></td>
            <td align='center'><b>总共</b></td>
            <td align='center'><b>已用</b></td>
            <td align='center'><b>可用</b></td>
        </tr>
            <%
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
            String selectSql1 = "select nvl(count(*),0) from uf_attendance where attendancestatus=0 and CURDATE like '%" + month + "%'  ";
            int cnt2 = getId(selectSql1); //整天都出勤的天数
            String selectSql2 = "select nvl(count(*),0) from uf_attendance where attendancestatus=2 and CURDATE like '%" + month + "%'  ";
            int cnt3 = getId(selectSql2);//上午半天出勤的天数
            double dueDays= cnt2 + cnt3*0.5;//应出勤天数
            double basicWorkTime = (cnt2 * 7.5 + cnt3 * 6.5); //基本工时

            List<String> curdateList1 = new ArrayList<String>();//用于接收当前日期存在打卡记录的集合
            String curdateSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus=0";
            //处理合同开始时间在当月或合同结束时间在当月
            String startDateSql="select startdate from hrmresource where id='"+userid+"'";
            String contractStartDate=getName(startDateSql);
            //如果合同开始时间为空，则赋值为2000-01-01
            contractStartDate =(contractStartDate==null||contractStartDate.isEmpty())?"2000-01-01":contractStartDate;
            String endDateSql="select enddate from hrmresource where id='"+userid+"'";
            String contractEndDate=getName(endDateSql);
            //如果合同开始结束为空，则赋值为2100-01-01
            contractEndDate =(contractEndDate==null||contractEndDate.isEmpty())?"2100-01-01":contractEndDate;
			if(month.equals(contractStartDate.substring(0,7))){
                curdateSql +=" and curdate >= '"+contractStartDate+"' ";
            }
            if(month.equals(contractEndDate.substring(0,7))){
                curdateSql +=" and curdate <= '"+contractEndDate+"' ";
            }
            List<String> curdateList=getList(curdateSql);//出勤整天的集合

            List<String> saturdayList1 = new ArrayList<String>();//用于接收当前存在打卡记录的集合
            String saturdayForWorkSql = "select curdate from uf_attendance where curdate like '%" + month + "%' and attendancestatus=2 ";
            if(month.equals(contractStartDate.substring(0,7))){
                saturdayForWorkSql +=" and curdate >= '"+contractStartDate+"' ";
            }
            if(month.equals(contractEndDate.substring(0,7))){
                saturdayForWorkSql +=" and curdate <= '"+contractEndDate+"' ";
            }
			List<String> saturdayList=getList(saturdayForWorkSql);//出勤半天的集合

            String sql = "SELECT (SELECT subcompanyname FROM hrmsubcompany WHERE id = hre.subcompanyid1) AS subcompanyname,hde.departmentname," +
            "hre.workCode,hre.lastname,hsc.signDate,hsc.signTime,hsc.signType,hre.id,(SELECT COUNT( isholiday ) FROM uf_attendance WHERE" +
            " curdate BETWEEN '"+ysdate+"' AND '"+yedate+"' AND isholiday = 0) AS holiday FROM hrmresource hre LEFT JOIN hrmschedulesign hsc " +
            "ON hre.id = hsc.userid AND hsc.signDate BETWEEN '"+checkMinDate+"' AND '"+checkMaxDate+"' AND hsc.isInCom = '1' LEFT JOIN " +
            "hrmdepartment hde ON hre.departmentid=hde.id WHERE hre.accounttype !=1 and hre.id= '"+userid+"' AND CASE WHEN hre.startdate is NULL " +
            "THEN '"+checkMaxDate+"' ELSE hre.startdate END <= '"+checkMaxDate+"' AND CASE WHEN hre.enddate is NULL THEN '"+checkMinDate+"' ELSE " +
            "hre.enddate END >= '"+checkMinDate+"' ORDER BY hde.id,hsc.signDate ASC";
            //定义集合，把数据进行封装
            Map<String,Map<String,List<String>>> areaResult = getAreaResult(sql);
            //单独处理总经理考勤报表
            //判断获取的数据是否为空
            if(areaResult!=null && areaResult.size()>0){
                //获取结果集所有键的集合，用keySet()方法实现
                Set<String> keySet = areaResult.keySet();

                double countHours=0.0;//上午旷工小时数
                double countHours1=0.0;//下午旷工小时数
                double countHours2=0.0;//周六旷工小时数
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
                     changeBusinessTripTime(value,id,likeDate,"1","2");
                    //调用方法，改变异常考勤时的打卡时间
                    changeAbnormalSignTime(value,id,month);
                    double actualDays =0.0;//实际天数
                    double actualWorkingHours =0.0;//实际工时
                    for (String key3 : value.keySet()) {
                        //当天打卡集合
                        List<String> timesList = value.get(key3);
                        Collections.sort(timesList);
                        //调用getMorningTimeList(TreeSet<String> ts2)方法获取上午打卡时间集合
                        List<String> morningTimeList = getMorningTimeList(timesList);
                        //调用getAfternoonTimeList(TreeSet<String> ts2)方法获取下午打卡时间集合
                        List<String> afternoonTimeList = getAfternoonTimeList(timesList);
                        //调用getconfirmTimeList(List<String> afternoonTimeList)方法获取下午17:15之后的打卡时间集合
                        List<String> confirmTimeList = getConfirmTimeList(afternoonTimeList);
                        //调用getFinalTimeList(List<String> morningTimeList,List<String> afternoonTimeList,List<String> confirmTimeList)方法获取最终打卡时间集合
                        List<String> finalTimeList = getFinalTimeList(morningTimeList, afternoonTimeList, confirmTimeList);
                        //对哺乳假数据进行处理
                        List<String> newFinalTimeList=reviseFinalTimeList(finalTimeList,key3,id);
                        if(curdateList.contains(key3)){
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
                            //上午未打签到卡，签到签退再11：45之后打
                            for(String time6:morningList1){
                                if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                                    morningList1.remove(time6);
                                    break;
                                }
                            }
                            actualDays +=(morningList1.size()<=1)?0:0.5;
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
                            actualDays +=(afternoonList1Size<=1)?0:0.5;
                        }else if(saturdayList.contains(key3)){
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
                            actualDays +=(morningList1.size()<=1)?0:0.5;
                        }
                    }
                    out.println("<td align='center'>" + actualDays + "</td>");//实出勤

                     //调用方法，改变请假(调休)的打卡时间
                    changeLeaveTime(value,  id,likeDate,8,"3","4");
                    //调用方法，改变请假(年假)的打卡时间
                    changeLeaveTime(value,  id,likeDate,0,"3","4");
                    //调用方法，改变请假(事假)的打卡时间
                    changeLeaveTime(value,  id,likeDate,9,"5","6");
                    //判断value集合是否为空
                    if (value.size() > 0) {
                        //获取结果集所有键的集合，用keySet()方法实现
                        Set<String> valueSet = value.keySet();
                        //调用getDateTreeSet()方法对yyyy-MM-dd格式日期进行排序
                        TreeSet<String> ts1 = getDateTreeSet();
                        ts1.addAll(valueSet);
                        //遍历键的集合，获取到每一个键。用增强for实现
                        Map<String,List<String>> map1=new TreeMap<String, List<String>>();
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
                                //对哺乳假数据进行处理
								List<String> newFinalTimeList=reviseFinalTimeList(finalTimeList,key1,id);
                                map1.put(key1,newFinalTimeList);
                            }
                        }

                        for (String key3 : map1.keySet()) {
                            if(curdateList.contains(key3)){
                                List<String> finalTimeList = map1.get(key3);
                                List<String> morningList1=new LinkedList<String>();
                                List<String> afternoonList1=new LinkedList<String>();
                                for (String time5:finalTimeList){
                                    int time5ForMin=getTimeMin(time5);
                                    if(time5ForMin<720){
                                        morningList1.add(time5);
                                        Collections.sort(morningList1);
                                    }else{
                                        afternoonList1.add(time5);
                                        Collections.sort(afternoonList1);
                                    }
                                }
                                //计算上午打卡情况
                                for(String time6:morningList1){
                                    if(time6.endsWith("1")&&(time6.compareTo("11:45:00:1")>0)){
                                        morningList1.remove(time6);
                                        break;
                                    }
                                }

                                /*
                                *
                                * 计算带请假的迟到早退旷工小时数(周一-----周五上午)
                                *
                                * */
                                if(morningList1.size()<=1){
                                    //旷工小时数
                                    countHours +=3.25;
                                }else if(morningList1.size()==2){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    if(firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //上午两次打卡数据 则计算迟到早退 08:30:00:1 09:30:00:2
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        earlyTime += Math.max((705 - secondSignForMin), 0);
                                        List<String> LeaveList=getCurLeaveCondition(key3,id );
                                        //当天无请假记录或上午无请假时间
                                        if(LeaveList.isEmpty()||LeaveList==null){
                                            actualWorkingHours +=3.25;
                                        }else{
                                            Double relaxedHours =0.0;
                                            for(String leaveRecord:LeaveList){
                                                String startTime=leaveRecord.split(",")[1];
                                                //如果请假开始时间大于11：45，则取11：45,如果开始时间小于08：30,则取08：30，其余情况则取默认值
                                                startTime=getTimeMin(startTime)>705?"11:45":getTimeMin(startTime)<510?"08:30":startTime;
                                                String endTime=leaveRecord.split(",")[2];
                                                //如果请假开始时间大于11：45，则取11：45,否则取默认值
                                                endTime=getTimeMin(endTime)>705?"11:45":getTimeMin(endTime)<510?"08:30":endTime;
                                                relaxedHours +=Double.parseDouble(getDifferenceHours(startTime,endTime));
                                            }
                                            actualWorkingHours +=3.25-relaxedHours;
                                        }
                                    }else if(firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //上午两次打卡记录， 08:30:00:1 11:00:00:4
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        countHours +=((705-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-secondSignForMin)/60)):0;
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String startTime=leaveRecord.split(",")[1];//请假开始时间
                                            startTime =startTime.compareTo("08:30")<=0?"08:30":startTime;
                                            actualWorkingHours +=Double.parseDouble(getDifferenceHours("08:30",startTime));//计算早上八点半到请假开始时间这段时间的实际工时
                                        }
                                    }else if(!firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //上午两次请假数据 则计算旷工小数 08:30:00:3, 11:45:00:4
                                        countHours +=(((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0)+(((705-secondSignForMin)>=0)?Double.valueOf(df11.format((float)(705-secondSignForMin)/60)):0);
                                    }else if(!firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //上午两次打卡记录， 08:30:00:3 11:30:00:2
                                        countHours +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        earlyTime += Math.max((705 - secondSignForMin), 0);
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String endTime =leaveRecord.split(",")[2];//请假结束时间
                                            endTime =endTime.compareTo("11：45")>=0?"11:45":endTime;
                                            actualWorkingHours +=Double.parseDouble(getDifferenceHours(endTime,"11:45"));//计算请假结束时间到11：45这段时间的实际工时
                                        }
                                    }
                                }else if(morningList1.size()==3){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    //第三次打卡
                                    String thirdSign=morningList1.get(2);
                                    //第三次打卡对应的分钟数
                                    int thirdSignForMin=getTimeMin(thirdSign);
                                    if(firstSign.endsWith("1")){
                                        //上午三条记录 08：30：00：1  10：00：00：3 11：45：00：4
                                        //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                        countHours +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        countHours +=((secondSignForMin-firstSignForMin)>=0)?Double.parseDouble(df11.format((float)(secondSignForMin-firstSignForMin)/60)):0;
                                        countHours +=((705-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-thirdSignForMin)/60)):0;
                                    }else if(thirdSign.endsWith("1")){
                                        //上午三条记录 08：30：00：3  10：00：00：4 11：00：00：1
                                        //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                        countHours +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        countHours +=((thirdSignForMin-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(thirdSignForMin-secondSignForMin)/60)):0;
                                        countHours +=((705-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-thirdSignForMin)/60)):0;
                                    }
                                }else if(morningList1.size()==4){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    //第三次打卡
                                    String thirdSign=morningList1.get(2);
                                    //第三次打卡对应的分钟数
                                    int thirdSignForMin=getTimeMin(thirdSign);
                                    //第四次打卡
                                    String forthSign=morningList1.get(3);
                                    //第四次打卡对应的分钟数
                                    int forthSignForMin=getTimeMin(forthSign);
                                    if(firstSign.endsWith("1")){
                                        //08：30：00：1 09:30:00:2 10：00：00：3 11：00：00：4
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        earlyTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        countHours +=((705-forthSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-forthSignForMin)/60)):0;
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours("08:30",thirdSign));//计算早上八点半到请假开始时间这段时间的实际工时
                                    }else if(thirdSign.endsWith("1")){
                                        //上午四条记录 08：40：00：3 09:30:00:4 10：00：00：1 11：00：00：2
                                        countHours +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        lateTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        earlyTime += Math.max((705 - forthSignForMin), 0);
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours(secondSign,"11:45"));//计算请假结束时间到11：45这段时间的实际工时
                                    }
                                }
                                List<String> afternoonList2=new LinkedList<String>();
                                for(String time6:afternoonList1){
                                    if(time6.endsWith("1")&&(time6.compareTo("17:15:00:1")>0)){
                                        afternoonList1.remove(time6);
                                        break;
                                    }
                                }
                                for (String clockOut : afternoonList1) {
                                    if (clockOut.endsWith("2")||clockOut.endsWith("4")||clockOut.endsWith("6")||clockOut.endsWith("8")) {
                                        afternoonList2.add(clockOut);
                                    }
                                }
                                int afternoonList1Size=afternoonList1.size();
                                afternoonList1Size=(afternoonList2.size()>=2)?(afternoonList1Size-afternoonList2.size()+1):afternoonList1Size;
                                /*
                                *
                                * 计算带请假的迟到早退旷工小时数(周一-----周五下午)
                                *
                                * */
                                if(afternoonList1Size<=1){
                                    countHours1 +=4.25;
                                }else if(afternoonList1Size==2){
                                    //下午第一次打卡
                                    String firstSign=afternoonList1.get(0);
                                    //下午第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //下午第二次打卡
                                    String secondSign=afternoonList1.get(1);
                                    //下午第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    if(firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //下午两次打卡数据 则计算迟到早退 13:30:00:1 17:00:00:2
                                        lateTime += Math.max((firstSignForMin - 795), 0);
                                        earlyTime += Math.max((1035 - secondSignForMin), 0);
                                        List<String> LeaveList=getCurLeaveCondition(key3,id );
                                        Double relaxedHours =0.0;
                                        for(String leaveRecord:LeaveList){
                                            String startTime=leaveRecord.split(",")[1];
                                            //如果请假开始时间大于17：15，则取17：15,如果开始时间小于13:00,则取13:00，其余情况则取默认值
                                            startTime=getTimeMin(startTime)>1035?"17:15":getTimeMin(startTime)<780?"13:00":startTime;
                                            String endTime=leaveRecord.split(",")[2];
                                            //如果请假开始时间大于17：15，则取17：15,否则取默认值
                                            endTime=getTimeMin(endTime)>1035?"17:15":getTimeMin(endTime)<780?"13:00":endTime;
                                            relaxedHours +=Double.parseDouble(getDifferenceHours(startTime,endTime));
                                        }
                                        actualWorkingHours +=4.25-relaxedHours;
                                    }else if(firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //下午两次打卡记录， 14:00:00:1 16:00:00:4
                                        Double relaxedHours =0.0;
                                        lateTime +=((firstSignForMin-795)>0)?(firstSignForMin-510):0;
                                        countHours1 +=((1035-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(1035-secondSignForMin)/60)):0;
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String startTime=leaveRecord.split(",")[1];//请假开始时间
                                            //如果请假开始时间大于17：15，则取17：15,如果开始时间小于13:00,则取13:00，其余情况则取默认值
                                            startTime=getTimeMin(startTime)>1035?"17:15":getTimeMin(startTime)<780?"13:00":startTime;
                                            String endTime=leaveRecord.split(",")[2];
                                            //如果请假开始时间大于17：15，则取17：15,否则取默认值
                                            endTime=getTimeMin(endTime)>1035?"17:15":getTimeMin(endTime)<780?"13:00":endTime;
                                            relaxedHours +=Double.parseDouble(getDifferenceHours(startTime,endTime));
                                        }
                                        actualWorkingHours +=4.25-relaxedHours;
                                    }else if(!firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //下午两次请假数据 则计算旷工小数  14:00:00:3 16:00:00:4
                                        countHours1 +=(((firstSignForMin-780)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-780)/60)):0)+
                                        (((1035-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(1035-secondSignForMin)/60)):0);
                                    }else if(!firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //下午两次打卡记录， 14:00:00:3 16:15:00:2
                                        countHours1 +=((firstSignForMin-780)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-780)/60)):0;
                                        earlyTime += Math.max((1035 - secondSignForMin), 0);
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String endTime =leaveRecord.split(",")[2];//请假结束时间
                                            actualWorkingHours +=Double.parseDouble(getDifferenceHours(endTime,"17:15"));//计算请假结束时间到17:15这段时间的实际工时
                                        }
                                    }
                                }else if(afternoonList1Size==3){
                                        //下午第一次打卡
                                        String firstSign=afternoonList1.get(0);
                                        //下午第一次打卡对应的分钟数
                                        int firstSignForMin=getTimeMin(firstSign);
                                        //下午第二次打卡
                                        String secondSign=afternoonList1.get(1);
                                        //下午第二次打卡对应的分钟数
                                        int secondSignForMin=getTimeMin(secondSign);
                                        //下午第三次打卡
                                        String thirdSign=afternoonList1.get(2);
                                        //下午第三次打卡对应的分钟数
                                        int thirdSignForMin=getTimeMin(thirdSign);
                                        //下午第四次打卡
                                        String forthSign=afternoonList1.get(3);
                                        //下午第四次打卡对应的分钟数
                                        int forthSignForMin=getTimeMin(forthSign);
                                        if(firstSign.endsWith("1")){
                                            //上午三条记录 13：30：00：1  15：00：00：3 17：00：00：4
                                            //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                            countHours1 +=((firstSignForMin-780)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-780)/60)):0;
                                            countHours1 +=((secondSignForMin-firstSignForMin)>=0)?Double.parseDouble(df11.format((float)(secondSignForMin-firstSignForMin)/60)):0;
                                            countHours1 +=((1035-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(1035-thirdSignForMin)/60)):0;
                                        }else if(thirdSign.endsWith("1")){
                                            //上午三条记录 13：30：00：3  15：00：00：4 17：00：00：1
                                            //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                            countHours1 +=((firstSignForMin-780)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-780)/60)):0;
                                            countHours1 +=((thirdSignForMin-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(thirdSignForMin-secondSignForMin)/60)):0;
                                            countHours1 +=((1035-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(1035-thirdSignForMin)/60)):0;
                                        }else{
                                            //下午请假两次情况 单独处理计算旷工小时数20201016
                                            double leaveHour1 =((secondSignForMin-firstSignForMin)>=0)?Double.parseDouble(df11.format((float)(secondSignForMin-firstSignForMin)/60)):0;
                                            double leaveHour2 =((forthSignForMin-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(forthSignForMin-thirdSignForMin)/60)):0;
                                            countHours1 +=4.25- leaveHour1- leaveHour2;
                                        }
                                }else if(afternoonList1Size>=4){
                                    //下午第一次打卡
                                    String firstSign=afternoonList1.get(0);
                                    //下午第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //下午第二次打卡
                                    String secondSign=afternoonList1.get(1);
                                    //下午第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    //下午第三次打卡
                                    String thirdSign=afternoonList1.get(2);
                                    //下午第三次打卡对应的分钟数
                                    int thirdSignForMin=getTimeMin(thirdSign);
                                    //下午第四次打卡
                                    String forthSign=afternoonList1.get(3);
                                    //下午第四次打卡对应的分钟数
                                    int forthSignForMin=getTimeMin(forthSign);
                                    if(firstSign.endsWith("1")){
                                        //下午四条记录13：30：00：1 15:30:00:2 16：00：00：3 17：00：00：4
                                        lateTime += Math.max((firstSignForMin - 795), 0);
                                        earlyTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        countHours1 +=((1035-forthSignForMin)>=0)?Double.parseDouble(df11.format((float)(1035-forthSignForMin)/60)):0;
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours("13:00",thirdSign));//计算下午1点到请假开始时间这段时间的实际工时
                                    }else if(thirdSign.endsWith("1")){
                                        //下午四条记录 13：30：00：3 15:30:00:4 16：00：00：1 17：00：00：2
                                        countHours1 +=((firstSignForMin-780)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-780)/60)):0;
                                        lateTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        earlyTime += Math.max((1035 - forthSignForMin), 0);
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours(forthSign,"17:15"));//计算请假结束时间到17：15这段时间的实际工时
                                    }
                                }
                                curdateList1.add(key3);
                            }
                            else if(saturdayList.contains(key3)){
                                List<String> finalTimeList = map1.get(key3);//周六集合
                                List<String> morningList1=new LinkedList<String>();
                                for (String time5:finalTimeList){
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
                                /*
                                *
                                * 计算带请假的迟到早退旷工小时数(周六上午)
                                *
                                * */
                                if(morningList1.size()<=1){
                                    //旷工小时数
                                    countHours2 +=3.25;
                                }else if(morningList1.size()==2){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    if(firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //上午两次打卡数据 则计算迟到早退 08:30:00:1 09:30:00:2
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        earlyTime += Math.max((705 - secondSignForMin), 0);
                                        List<String> LeaveList=getCurLeaveCondition(key3,id );
                                        if(LeaveList.isEmpty()||LeaveList==null){
                                            actualWorkingHours +=6.5;
                                        }else{
                                            Double relaxedHours =0.0;
                                            for(String leaveRecord:LeaveList){
                                                String startTime=leaveRecord.split(",")[1];
                                                //如果请假开始时间大于11：45，则取11：45,如果开始时间小于08：30,则取08：30，其余情况则取默认值
                                                startTime=getTimeMin(startTime)>705?"11:45":getTimeMin(startTime)<510?"08:30":startTime;
                                                String endTime=leaveRecord.split(",")[2];
                                                //如果请假开始时间大于11：45，则取11：45,否则取默认值
                                                endTime=getTimeMin(endTime)>705?"11:45":getTimeMin(endTime)<510?"08:30":endTime;
                                                relaxedHours +=Double.parseDouble(getDifferenceHours(startTime,endTime));
                                            }
                                            actualWorkingHours +=6.5-relaxedHours;
                                        }
                                    }else if(firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //上午两次打卡记录， 08:30:00:1 11:00:00:4
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        countHours2 +=((705-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-secondSignForMin)/60)):0;
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String startTime=leaveRecord.split(",")[1];//请假开始时间
                                            startTime =startTime.compareTo("08:30")<=0?"08:30":startTime;
                                            actualWorkingHours +=Double.parseDouble(getDifferenceHours("08:30",startTime))*2;//计算早上八点半到请假开始时间这段时间的实际工时
                                        }
                                    }else if(!firstSign.endsWith("1")&&!secondSign.endsWith("2")){
                                        //上午两次请假数据 则计算旷工小数 08:30:00:3, 11:45:00:4
                                        countHours2 +=(((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0)+(((705-secondSignForMin)>=0)?Double.valueOf(df11.format((float)(705-secondSignForMin)/60)):0);
                                    }else if(!firstSign.endsWith("1")&&secondSign.endsWith("2")){
                                        //上午两次打卡记录， 08:30:00:3 11:30:00:2
                                        countHours2 +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        earlyTime += Math.max((705 - secondSignForMin), 0);
                                        List<String> leaveRecordList=getCurLeaveCondition(key3,id );//获取当天打卡记录 计算出请假小时数
                                        for (String leaveRecord : leaveRecordList) {
                                            String endTime =leaveRecord.split(",")[2];//请假结束时间
                                            endTime =endTime.compareTo("11：45")>=0?"11:45":endTime;
                                            actualWorkingHours +=Double.parseDouble(getDifferenceHours(endTime,"11:45"))*2;//计算请假结束时间到11：45这段时间的实际工时
                                        }
                                    }
                                }else if(morningList1.size()==3){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    //第三次打卡
                                    String thirdSign=morningList1.get(2);
                                    //第三次打卡对应的分钟数
                                    int thirdSignForMin=getTimeMin(thirdSign);
                                    if(firstSign.endsWith("1")){
                                        //上午三条记录 08：30：00：1  10：00：00：3 11：45：00：4
                                        //上午第一次打卡时间前后计算旷工 第三次打卡时间计算旷工小时数
                                        countHours2 +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        countHours2 +=((secondSignForMin-firstSignForMin)>=0)?Double.parseDouble(df11.format((float)(secondSignForMin-firstSignForMin)/60)):0;
                                        countHours2 +=((705-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-thirdSignForMin)/60)):0;
                                    }else if(thirdSign.endsWith("1")){
                                        //上午三条记录 08：30：00：3  10：00：00：4 11：00：00：1
                                        //上午第一次打卡时间计算旷工小时数 第三次打卡时间前后计算旷工
                                        countHours2 +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        countHours2 +=((thirdSignForMin-secondSignForMin)>=0)?Double.parseDouble(df11.format((float)(thirdSignForMin-secondSignForMin)/60)):0;
                                        countHours2 +=((705-thirdSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-thirdSignForMin)/60)):0;
                                    }
                                }else if(morningList1.size()==4){
                                    //第一次打卡
                                    String firstSign=morningList1.get(0);
                                    //第一次打卡对应的分钟数
                                    int firstSignForMin=getTimeMin(firstSign);
                                    //第二次打卡
                                    String secondSign=morningList1.get(1);
                                    //第二次打卡对应的分钟数
                                    int secondSignForMin=getTimeMin(secondSign);
                                    //第三次打卡
                                    String thirdSign=morningList1.get(2);
                                    //第三次打卡对应的分钟数
                                    int thirdSignForMin=getTimeMin(thirdSign);
                                    //第四次打卡
                                    String forthSign=morningList1.get(3);
                                    //第四次打卡对应的分钟数
                                    int forthSignForMin=getTimeMin(forthSign);
                                    if(firstSign.endsWith("1")){
                                        //08：30：00：1 09:30:00:2 10：00：00：3 11：00：00：4
                                        lateTime += Math.max((firstSignForMin - 510), 0);
                                        earlyTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        countHours2 +=((705-forthSignForMin)>=0)?Double.parseDouble(df11.format((float)(705-forthSignForMin)/60)):0;
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours("08:30",thirdSign))*2;//计算早上八点半到请假开始时间这段时间的实际工时
                                    }else if(thirdSign.endsWith("1")){
                                        //上午四条记录 08：40：00：3 09:30:00:4 10：00：00：1 11：00：00：2
                                        countHours2 +=((firstSignForMin-510)>0)?Double.parseDouble(df11.format((float)(firstSignForMin-510)/60)):0;
                                        lateTime += Math.max((thirdSignForMin - secondSignForMin), 0);
                                        earlyTime += Math.max((705 - forthSignForMin), 0);
                                        actualWorkingHours +=Double.parseDouble(getDifferenceHours(forthSign,"11:45"))*2;//计算请假结束时间到11：45这段时间的实际工时
                                    }
                                }
                                saturdayList1.add(key3);
                            }
                        }
                        curdateList.removeAll(curdateList1);
                        saturdayList.removeAll(saturdayList1);
                        out.println("<td align='center'>" + actualWorkingHours + "</td>");//实际工时
                        out.println("<td align='center'>" + holiday + "</td>");//节假日
                        out.println("<td align='center'>" + lateTime + "</td>");//迟到分钟数
                        out.println("<td align='center'>" + earlyTime + "</td>");//早退分钟数
                        //out.println("<td align='center'>" + (count+count1+count2+curdateList.size()+saturdayList.size()*0.5) + "</td>");//总旷工天数
                        out.println("<td align='center'>" + (countHours+countHours1+countHours2*2+curdateList.size()*7.5+saturdayList.size()*6.5) + "</td>");//旷工小时数
                         }else{
                            //当月没有打卡记录
                            out.println("<td align='center'>" + 0 + "</td>");//实际工时
                            out.println("<td align='center'>" + holiday + "</td>");//节假日
                            out.println("<td align='center'>" + 0 + "</td>");//迟到分钟数
                            out.println("<td align='center'>" + 0 + "</td>");//早退分钟数
                            out.println("<td align='center'>" + basicWorkTime + "</td>");//旷工天数
                        }
                        //异常流程次数
                        String abnormalTimeSql = "select nvl(sum(morning_sign_in),0)+nvl(sum(afternoon_sign_in),0)+nvl(sum(morning_sign_back),0)+nvl(sum(afternoon_sign_back),0) from formtable_main_1125 where abnormal_date like '%" + month + "%' and userid='"+userid+"' ";
                        int cnt5=getId(abnormalTimeSql);
                        out.println("<td align='center'>" + cnt5 + "</td>");//异常流程次数
                        //请假数据获取 获取当月的请假数据 获取上月底至本月初的请假数据 获取本月底至下月初的请假数据
                        for (Integer num1 : getLeaveStandard()) {
                            //获取当月的请假数据
                            String leaveSql = "select case when sum(hours) is null then 0.00 else sum(hours) end as 总天数 from uf_AskForLeave where userid='"+userid+"' and " +
                                    " type=" + num1 + " and start_date like '%" + month + "%' and end_date like '%" + month + "%' ";
                            RecordSet rs13 = new RecordSet();
                            rs13.execute(leaveSql);
                            Double cnt7  ;
                            rs13.next();
                            cnt7 = rs13.getDouble(1);
                            cnt7 +=getLeaveTime(num1,month,workCode);
                            cnt7 +=getLeaveTime1(num1,month,workCode);
                            DecimalFormat df2 = new DecimalFormat("0.00");
                            String cnt77 = df2.format(cnt7);
                            out.println("<td align='center'>" + cnt77 + "</td>");
                        }
                        //加点工时
                        String OvertimebyHourSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                "WHERE WORK_DATE LIKE '%" + month + "%' AND userid='"+userid+"' AND " +
                                "(OVERTIME_TYPE IN (0,2) or (OVERTIME_TYPE in (3) and break_off=1 and WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where ATTENDANCESTATUS in(0)))) ";
                        RecordSet rs15 = new RecordSet();
                        rs15.execute(OvertimebyHourSql);
                        rs15.next();
                        Double cnt8 = rs15.getDouble(1);
                        DecimalFormat decimalFormat1=new DecimalFormat("0.00");
                        String newcnt8=decimalFormat1.format(cnt8);
                        out.println("<td align='center'>" + newcnt8 + "</td>");//加点工时
                        //加班工时
                        String addedHoursSql = "SELECT case when SUM (OVERTIME_HOURS) is null then 0.00 else SUM (OVERTIME_HOURS) end FROM uf_WorkOvertime " +
                                "WHERE WORK_DATE LIKE '%" + month + "%' AND userid=(select id from hrmresource where workcode like '%" + workCode + "%') and " +
                                "WORK_DATE in(SELECT CURDATE from UF_ATTENDANCE where ATTENDANCESTATUS in(1,2))  and OVERTIME_TYPE in (1,3) ";
                        RecordSet rs16 = new RecordSet();
                        rs16.execute(addedHoursSql);
                        rs16.next();
                        Double cnt9 = rs16.getDouble(1);
                        String newcnt9=decimalFormat1.format(cnt9);
                        out.println("<td align='center'>" + newcnt9 + "</td>");//加班工时
                        //调休工时
                        String paidLeaveTimeSql  =  "SELECT nvl(SUM(overtime_hours),0.00) FROM uf_WorkOvertime WHERE break_off = 0 AND WORK_DATE LIKE '%" + month + "%' AND userid='"+userid+"'";
                        Double cnt11=getDoubleNumber(paidLeaveTimeSql);
                        String newcnt10=decimalFormat1.format(cnt11);
                        out.println("<td align='center'>" + newcnt10 + "</td>");//调休工时

                        //剩余调休时间
                        String spareLeaveSql = "select nvl(SUM (OVERTIME_HOURS),0.00) from uf_TimePoolB where userid='"+userid+"' and iseffective=0 ";
                        RecordSet rs10 = new RecordSet();
                        rs10.execute(spareLeaveSql);
                        rs10.next();
                        Double cnt6 = rs10.getDouble(1);
                        DecimalFormat df1 = new DecimalFormat("0.00");
                        String cnt66 = df1.format(cnt6);
                        out.println("<td align='center'>" + cnt66 + "</td>");//剩余调休工时
                        //获取年假数据 总时长 已用时长 剩余时长
                        String annualInfoSql = "select total_days,used_days,DECODE(total_days-used_days,null,0,total_days-used_days) spareHours from uf_annual_info where userid='"+userid+"'  ";
                        RecordSet rs11 = new RecordSet();
                        rs11.execute(annualInfoSql);
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
            <%!
                public static Long getTimeMillis(Calendar c) {
                    c.set(Calendar.DAY_OF_MONTH, c.get(Calendar.DAY_OF_MONTH) + 1);
                    return c.getTimeInMillis();
                }
            %>

            <%!
                /**
                 * 获取时间的秒数getTime(String s)
                 * @param s
                 * @return Integer
                 */
                public static Integer getTime(String s) {
                    String[] arr = s.split(":");
                    int hour = Integer.parseInt(arr[0]);
                    int minute = Integer.parseInt(arr[1]);
                    int seconds = Integer.parseInt(arr[2]);
                    return hour * 3600 + minute * 60 + seconds;
                }
            %>

            <%!
                /**
                 * 对yyyy-MM-dd格式日期进行排序getDateTreeSet()
                 * @return  TreeSet<String>
                 */
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

            <%!
                /**
                 * 获取从数据库查询到的数据进行封装getAreaResult(String sql)
                 * @param sql
                 * @return Map<String, Map<String, List<String>>>
                 */
                public static Map<String, Map<String, List<String>>> getAreaResult(String sql) {
                    RecordSet rs = new RecordSet();
                    rs.execute(sql);
                    //定义集合，把数据进行封装
                    Map<String, Map<String, List<String>>> areaResult = new TreeMap<String, Map<String, List<String>>>();
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
                        //员工id
                        String id = Util.null2String(rs.getString("id"));
                        //法定节假日
                        String holiday = Util.null2String(rs.getString("holiday"));
                        if (!signTime.isEmpty() && !signType.isEmpty()) {
                            signTime = signTime + ":" + signType;
                        }
                        //定义集合的key值
                        String key = subcompanyname + "," + departmentname + "," + workCode + "," + lastname + "," + id + "," + holiday;

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

            <%!
                /**
                 * 获取上午时段的打卡时间
                 * @param list
                 * @return List<String>
                 */
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
                    return morningTimeList;
                }
            %>
            <%!
                /**
                 * 获取下午时段的打卡时间
                 * @param list
                 * @return List<String>
                 */
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

            <%!
                /**
                 * 获取下午17:15时段之后的打卡时间
                 * @param afternoonTimeList
                 * @return List<String>
                 */
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
                    return confirmTimeList;
                }
            %>

            <%!
                /**
                 * 获取下午17:15时段之前的最终打卡时间
                 * @param afternoonTimeList
                 * @return List<String>
                 */
                public static List<String> getFinalAfternoonTimeList(List<String> afternoonTimeList) {
                    //定义下午17:15时段之前的最终打卡时间的集合
                    List<String> finalAfternoonTimeList = new ArrayList<String>();
                    List<String> afternoonTimeList1 = new ArrayList<String>();
                    List<String> leaveTimeList = new ArrayList<String>();
                    for (String cTime : afternoonTimeList) {
                        if (cTime.endsWith("1") || cTime.endsWith("2")) {
                            afternoonTimeList1.add(cTime);
                        } else {
                            leaveTimeList.add(cTime);
                        }
                    }
                    for (int y = 0; y < afternoonTimeList1.size(); y++) {
                        String time = afternoonTimeList1.get(y);
                        String[] split1 = time.split(":");
                        int hour = Integer.parseInt(split1[0]);
                        int minute = Integer.parseInt(split1[1]);
                        int seconds = Integer.parseInt(split1[2]);
                        int typeInt = Integer.parseInt(split1[3]);
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
                public static void changeBusinessTripTime(Map<String, List<String>> value, String id, String month, String businessinFlag, String businessOutFlag) {
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
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
                    while (rs1.next()) {
                        List<String> dateList = new ArrayList<String>();
                        List<String> finalDateList = new ArrayList<String>();
                        String startDate = Util.null2String(rs1.getString("start_date"));//出差开始日期
                        String endDate = Util.null2String(rs1.getString("end_date")); //出差结束日期
                        String startTime = Util.null2String(rs1.getString("start_time")); //出差开始时间
                        String endTime = Util.null2String(rs1.getString("end_time"));//出差结束时间
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
                                int isAttendance1 = getId(attendanceSql1);
                                if (isAttendance1 >= 1) {
                                    value.put(businesstripDate, businesstripTimeList1);
                                }
                            }
                            //根据用户id和日期查询出差开始当天是否有业务考勤打卡记录
                            String attendanceSql2 = "SELECT count(*)  from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + startDate + "'";
                            String attendanceSql3 = "SELECT count(*)  from mobile_sign ms,hrmresource hre WHERE ms.operater = hre.id and hre.id = " + id + " and ms.operate_date = '" + endDate + "'";
                            int isAttendance2 = getId(attendanceSql2);
                            int isAttendance3 = getId(attendanceSql3);
                            //出差开始日期和出差结束日期不是同一天
                            if (!startDate.equals(endDate)) {
                                //2.处理出差开始当天的考勤打卡时间
                                //出差开始日期当天的打卡记录集合
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
                                if (isAttendance2 >= 1) {
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
                    String sql = "SELECT abnormal_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from UF_ABNORMALSIGN  WHERE abnormal_date like '%" + month + "%' AND userid = " + id + "";
                    RecordSet rs = new RecordSet();
                    rs.execute(sql);
                    while (rs.next()) {
                        String abnormalDate = Util.null2String(rs.getString("abnormal_date"));//考勤异常日期
                        String morningSignIn = Util.null2String(rs.getString("morning_sign_in")); //上午签到考勤异常
                        String morningSignBack = Util.null2String(rs.getString("morning_sign_back")); //上午签退考勤异常
                        String afternoonSignIn = Util.null2String(rs.getString("afternoon_sign_in")); //下午签到考勤异常
                        String afternoonSignBack = Util.null2String(rs.getString("afternoon_sign_back")); //下午签退考勤异常
                        List<String> abnormalSignDate = new LinkedList<String>();
                        if (value.containsKey(abnormalDate)) {
                            abnormalSignDate = value.get(abnormalDate); //获取考勤异常当天的打卡时间集合
                        }
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
                                if (Integer.parseInt(valueDate.split("-")[1]) == Integer.parseInt(likeDate.split("-")[1])) {
                                    finalDateList.add(dateList.get(i));
                                }
                            }
                            for (String valueDate : finalDateList) {
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
                            //请假开始日期和请假结束日期不为同一天
                            if (!startDate.equals(endDate)) {
                                //----2020.07.13---start---
                                //处理调休(年假)请假开始当天的考勤打卡时间
                                String startDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + startDate + "'";//根据日期查询排版表
                                int startDateStatus = getId(startDateStatusSql);
                                if (startDateStatus == 0) {
                                    //正常出勤1天
                                    endTime = "17:15";
                                    changeTodayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);
                                } else if (startDateStatus == 2) {
                                    //单休六出勤半天
                                    endTime = "11:45";
                                    changeSaturdayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);
                                }
                                //调休(年假)请假结束日期当天的打卡记录集合
                                String endDateStatusSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                                int endDateStatus = getId(endDateStatusSql);
                                if (endDateStatus == 0) {
                                    //正常出勤1天
                                    startTime = "08:30";
                                    endTime = endTime.compareTo("17:15") >= 0 ? "17:15" : endTime;
                                    changeTodayTime(value, startTime, endTime, endDate, leaveinFlag, leaveoutFlag);
                                } else if (endDateStatus == 2) {
                                    //单休六出勤半天
                                    startTime = "08:30";
                                    endTime = endTime.compareTo("11:45") >= 0 ? "11:45" : endTime;
                                    changeSaturdayTime(value, startTime, endTime, endDate, leaveinFlag, leaveoutFlag);
                                }
                                //----2020.07.13---end---
                            } else {
                                //请假开始日期和请假结束日期为同一天
                                String attendanceSql = "select attendancestatus from uf_attendance where curdate = '" + endDate + "'";//根据日期查询排版表
                                int attendancestatus = getId(attendanceSql);
                                if (attendancestatus == 0) {
                                    changeTodayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//正常出勤1天
                                } else if (attendancestatus == 2) {
                                    changeSaturdayTime(value, startTime, endTime, startDate, leaveinFlag, leaveoutFlag);//单休六出勤半天
                                }
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
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
                public static void changeTodayTime(Map<String, List<String>> value, String startTime, String endTime, String outdate, String leaveinFlag, String leaveoutFlag) {
                    //处理外出当天的考勤打卡时间
                    //外出当天的打卡记录集合
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
                    //---end---

                    //前提（结束时间一定大于开始时间）
                    //1.外出开始时间小于等于8:30,外出结束时间小于等于8:30
                    boolean result1 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) <= (8 * 60 + 30);
                    //2.外出开始时间小于等于8:30,外出结束时间小于11:45
                    boolean result2 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) > (8 * 60 + 30);
                    //3.外出开始时间小于等于8:30,外出时间小于13:00
                    boolean result3 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (11 * 60 + 45);
                    //4.外出开始时间小于等于8:30,外出时间小于17:15
                    boolean result4 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) > (13 * 60);
                    //5.外出开始时间小于等于8:30,外出时间大于等于17:15
                    boolean result5 = (startTimeForHours * 60 + startTimeForMinutes) <= (8 * 60 + 30) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                    //6.外出开始时间小于11:45,外出结束时间小于11:45
                    boolean result6 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) > (8 * 60 + 30);
                    //7.外出开始时间小于11:45,外出结束时间小于13:00
                    boolean result7 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (11 * 60 + 45);
                    //8.外出开始时间小于11:45,外出结束时间小于17:15
                    boolean result8 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (13 * 60);
                    //9.外出开始时间小于11:45,外出结束时间大于等于17:15
                    boolean result9 = (startTimeForHours * 60 + startTimeForMinutes) > (8 * 60 + 30) && (startTimeForHours * 60 + startTimeForMinutes) < (11 * 60 + 45) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                    //10.外出开始时间小于13:15,外出结束时间小于13:00
                    boolean result10 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) < (13 * 60);
                    //11.外出开始时间小于13:00,外出结束时间小于17:15
                    boolean result11 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (13 * 60);
                    //12.外出开始时间小于13:00,外出结束时间大于等于17:15
                    boolean result12 = (startTimeForHours * 60 + startTimeForMinutes) >= (11 * 60 + 45) && (startTimeForHours * 60 + startTimeForMinutes) <= (13 * 60) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                    //13.外出开始时间小于17:15,外出结束时间小于17:15
                    boolean result13 = (startTimeForHours * 60 + startTimeForMinutes) > (13 * 60) && (startTimeForHours * 60 + startTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) > (13 * 60);
                    //14.外出开始时间小于17:15,外出结束时间大于等于17:15
                    boolean result14 = (startTimeForHours * 60 + startTimeForMinutes) > (13 * 60) && (startTimeForHours * 60 + startTimeForMinutes) < (17 * 60 + 15) && (endTimeForHours * 60 + endTimeForMinutes) >= (17 * 60 + 15);
                    //15.外出开始时间大于等于17:15
                    boolean result15 = (startTimeForHours * 60 + startTimeForMinutes) >= (17 * 60 + 15);

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
                    } else if (result5) {
                        //外出开始时间小于等于8:30,外出时间大于等于17:15
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
                            String signOutTime = oldSignOutList.size() > 0 ? oldSignOutList.get(oldSignOutList.size() - 1) : "";//取最后一次上午签退时间
                            String signInTime = oldSignInList.size() > 0 ? oldSignInList.get(0) : "";//取第一次下午签到时间
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
                            if (signInTime.compareTo(endTime) <= 0 && !signInTime.equals("")) {
                                endTime = endTime.substring(0, 9) + "2";
                                gooutStartDate.set(gooutStartDate.indexOf(signInTime), endTime);
                            } else {
                                gooutStartDate.add(endTime);
                            }
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
            <!--处理上月底至本月初的请假数据-->
            <%!
                public static Double getLeaveTime(int num1, String month, String workCode) {
                    Double cnt7 = 0.0;
                    String leaveSql1 = " select end_date,end_time from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') and " +
                            " type=" + num1 + " and start_date not like '%" + month + "%' and end_date like '%" + month + "%' ";
                    RecordSet recordSet1 = new RecordSet();
                    recordSet1.execute(leaveSql1);
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
                    RecordSet recordSet2 = new RecordSet();
                    recordSet2.execute(endDateSql);
                    while (recordSet2.next()) {
                        int attendancestatus = recordSet2.getInt(1);
                        int endMin = Integer.parseInt(endTime.substring(0, 2)) * 60 + Integer.parseInt(endTime.substring(3, 5));
                        final boolean b = endMin >= 8 * 60 + 30 && endMin < 11 * 60 + 45;
                        if (attendancestatus == 0) {
                            if (b) {
                                cnt8 += Double.parseDouble(getDifferenceHours("08:30", endTime));

                            } else if (endMin >= 11 * 60 + 45 && endMin <= 13 * 60 + 15) {
                                cnt8 += 3.25;
                            } else if (endMin > 13 * 60 + 15 && endMin < 17 * 60 + 15) {
                                cnt8 += Double.parseDouble(getDifferenceHours("09:45", endTime));
                            } else if (endMin >= 17 * 60 + 15) {
                                cnt8 += 7.25;
                            }
                        } else if (attendancestatus == 2) {
                            if (b) {
                                cnt8 += Double.parseDouble(getDifferenceHours("08:30", endTime));
                            } else if (endMin >= 11 * 60 + 45) {
                                cnt8 += 3.25;
                            }
                        }
                    }
                    return cnt8;
                }
            %>
            <!--处理本月底至下月初的请假数据-->
            <%!
                public static Double getLeaveTime1(int num1, String month, String workCode) {
                    Double cnt7 = 0.0;
                    //获取本月底至下月初的数据
                    String leaveSql2 = " select start_date,start_time from uf_AskForLeave where userid=(select id from hrmresource where workcode='" + workCode + "') " +
                            "and type=" + num1 + " and start_date like '%" + month + "%' and end_date not like '%" + month + "%'";
                    RecordSet recordSet3 = new RecordSet();
                    recordSet3.execute(leaveSql2);
                    if (recordSet3.next()) {
                        String eDate = month + "-31";
                        String startDate = recordSet3.getString(1);
                        String startTime = recordSet3.getString(2);
                        //查询出月初至截止请假日期（不包含截止请假日期）的请假数据
                        String combineSql = "SELECT case when count(*) is null then 0 else count(*)*7.5 end from uf_attendance where curdate<='" + eDate + "'  and curdate>='" + startDate + "' " +
                                "and attendancestatus=0 union all SELECT case when count(*) is null then 0 else count(*)*3.25 end  from uf_attendance where curdate>='" + eDate + "'  and curdate<'" + startDate + "' " +
                                "and attendancestatus=2 ";
                        RecordSet recordSet4 = new RecordSet();
                        recordSet4.execute(combineSql);
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
                public static Double getNewHour(String startDate, String startTime) {
                    double cnt8 = 0.0;
                    String startDateSql = "select attendancestatus from uf_attendance where curdate='" + startDate + "'  ";
                    RecordSet recordSet2 = new RecordSet();
                    recordSet2.execute(startDateSql);
                    while (recordSet2.next()) {
                        int attendancestatus = recordSet2.getInt(1);
                        int startMin = Integer.parseInt(startTime.substring(0, 2)) * 60 + Integer.parseInt(startTime.substring(3, 5));
                        final boolean b = startMin >= 8 * 60 + 30 && startMin < 11 * 60 + 45;
                        if (attendancestatus == 0) {
                            if (b) {
                                cnt8 += Double.parseDouble(getDifferenceHours("08:30", startTime));
                            } else if (startMin >= 11 * 60 + 45 && startMin <= 13 * 60 + 15) {
                                cnt8 += 3.25;
                            } else if (startMin > 13 * 60 + 15 && startMin < 17 * 60 + 15) {
                                cnt8 += Double.parseDouble(getDifferenceHours("09:45", startTime));
                            } else if (startMin >= 17 * 60 + 15) {
                                cnt8 += 7.50;
                            }
                        } else if (attendancestatus == 2) {
                            if (b) {
                                cnt8 += Double.parseDouble(getDifferenceHours("08:30", startTime));
                            } else if (startMin >= 11 * 60 + 45) {
                                cnt8 += 3.25;
                            }
                        }
                    }
                    return cnt8;
                }
            %>
            <%!
                /**
                 * 获取半小时后的时间
                 * @param time
                 * @return String
                 */
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
            <%!
                /**
                 * 获取半小时前的时间
                 * @param curTime
                 * @return String
                 */
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
            <%!
                /**
                 * 将哺乳假数据添加到打卡集合中
                 * @param finalTimeList
                 * @param curdate
                 * @param id
                 * @return List<String>
                 */
                public static List<String> reviseFinalTimeList(List<String> finalTimeList, String curdate, String id) {
                    List<String> newFinalTimeList = new ArrayList<String>();//定义结合接收修正后的数据
                    //查询该用户拥有的哺乳假
                    String getLactationSql = "SELECT start_date,end_date,morning_sign_in,morning_sign_back,afternoon_sign_in,afternoon_sign_back from uf_lactation where userid='" + id + "' ";
                    RecordSet getLactationRs = new RecordSet();
                    getLactationRs.execute(getLactationSql);
                    while (getLactationRs.next()) {
                        String startDate = Util.null2String(getLactationRs.getString("start_date"));//哺乳假的开始日期
                        String endDate = Util.null2String(getLactationRs.getString("end_date"));//哺乳假的结束日期
                        String morningSignIn = Util.null2String(getLactationRs.getString("morning_sign_in"));//上午签到
                        String morningSignBack = Util.null2String(getLactationRs.getString("morning_sign_back"));//上午签退
                        String afternoonSignIn = Util.null2String(getLactationRs.getString("afternoon_sign_in"));//下午签到
                        String afternoonSignBack = Util.null2String(getLactationRs.getString("afternoon_sign_back"));//下午签退
                        //哺乳假1天1次，每次1小时
                        boolean result1 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到1小时
                        boolean result2 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退1小时
                        boolean result3 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//下午签到1小时
                        boolean result4 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签退1小时
                        //哺乳假1天2次，每次0.5小时
                        boolean result5 = (("1").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 上午签退
                        boolean result6 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签到 下午签到
                        boolean result7 = (("1").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签到 下午签退
                        boolean result8 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("0").equals(afternoonSignBack));//上午签退 下午签到
                        boolean result9 = (("0").equals(morningSignIn)) && (("1").equals(morningSignBack)) && (("0").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//上午签退 下午签退
                        boolean result10 = (("0").equals(morningSignIn)) && (("0").equals(morningSignBack)) && (("1").equals(afternoonSignIn)) && (("1").equals(afternoonSignBack));//下午签到 下午签退
                        //比较打卡日期 在哺乳假开始日期与结束日期之间
                        if (startDate.compareTo(curdate) <= 0 && endDate.compareTo(curdate) >= 0) {
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
            <%!
                /**
                 * 查询sql结果为string对应的名称
                 * @param sql
                 * @return String
                 */
                public static String getName(String sql) {
                    RecordSet recordSet = new RecordSet();
                    recordSet.execute(sql);
                    recordSet.next();
                    return recordSet.getString(1);
                }
            %>
            <%!
                /**
                 * 查询sql结果为int对应的名称
                 * @param getSql
                 * @return int
                 */
                public static int getId(String getSql) {
                    RecordSet recordSet = new RecordSet();
                    recordSet.execute(getSql);
                    recordSet.next();
                    return recordSet.getInt(1);
                }
            %>
            <%!
                /**
                 * 查询sql结果为double对应的名称
                 * @param getSql
                 * @return double
                 */
                public static double getDoubleNumber(String getSql) {
                    RecordSet recordSet = new RecordSet();
                    recordSet.execute(getSql);
                    recordSet.next();
                    return recordSet.getDouble(1);
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
                 * 计算两个时间相差的小时数(保留两位小数)
                 * @param startTime
                 * @param endTime
                 * @return String
                 */
                private static String getDifferenceHours(String startTime, String endTime) {
                    DecimalFormat df = new DecimalFormat("0.00");
                    int firstSignForMin1 = getTimeMin(startTime);//第一次打卡对应的分钟数
                    int secondSignForMin1 = getTimeMin(endTime);//第二次打卡对应的分钟数
                    return df.format((float) (secondSignForMin1 - firstSignForMin1) / 60);
                }
            %>
            <%!
                /**
                 * 获取各种假期类型的集合 0年休假 8调休 9事假
                 * @return List<Integer>
                 */
                private static List<Integer> getLeaveStandard() {
                    List<Integer> typeList = new ArrayList<Integer>();
                    typeList.add(0, 8);
                    typeList.add(1, 0);
                    typeList.add(2, 9);
                    return typeList;
                }
            %>
            <%!
                /**
                 * 将sql查询结果封装成集合
                 * @param sql
                 * @return  List<String>
                 */
                private static List<String> getList(String sql){
                    List<String> list1=new LinkedList<String>();
                    RecordSet recordSet=new RecordSet();
                    recordSet.execute(sql);
                    while (recordSet.next()){
                        String s1=recordSet.getString(1);
                        list1.add(s1);
                    }
                    return list1;
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
        </table>
</div>
</body>

