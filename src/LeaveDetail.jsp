<!-- 请假明细表 -->
<%@ page language="java" import="java.util.*" pageEncoding="UTF-8" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="weaver.conn.RecordSet" %>
<%@page import="weaver.general.BaseBean" %>
<%@ page import="weaver.general.Util" %>
<%@ page import="java.util.*" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ include file="/hrm/header.jsp" %>
<%@ page import="weaver.general.Util" %>
<%@ page import="weaver.conn.RecordSet" %>
<%@ page import="weaver.iiot.studytest.bzt.utils.DisassembleUtil" %>

<jsp:useBean id="BaseBean" class="weaver.general.BaseBean" scope="page"/>
<%
    String userId = Util.null2String(request.getParameter("userId"));
    String month = Util.null2String(request.getParameter("month"));
    String imagefilename = "/images/hdReport_wev8.gif", needfav = "1", needhelp = "";
    String titlename = "员工请假明细表";
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

//打卡时间戳(以分为单位)
// 8：30
    int stime_start = 510 ;
// 11:45
    int stime_end = 705;
// 12:00
    int noon = 720;
// 13:00
    int etime_start = 780;
// 17:15
    int etime_end = 1035;
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
			 DisassembleUtil util =  new DisassembleUtil();
             Map<String, String> dataMap = new HashMap();
             ArrayList<Map<String, String>> myDetailList = new ArrayList();
			 RecordSet detail_rs = new RecordSet();

			 //查询请假明细
             String detailSql =
                " select curdate as 请假日期,"+
                " (case when start_date=end_date then '当日' when start_date<curdate and curdate<end_date then '中间日'"+ 
                " when start_date<curdate and curdate=end_date then '结束日' when start_date=curdate and curdate<end_date then '开始日' else '非工作日' end) as 请假小时类型,"+
                " (case when type=0 then '年休假'  when type=8 then '调休' when type=9 then '事假' end) as 请假类型,"+
                " (case when attendancestatus=2 then '单休周六上午' WHEN attendancestatus=0 THEN '工作日' else '非工作日' end) as 请假类别,"+
                " start_time,end_time,days"+
                " from uf_askforleave al"+
                " inner join uf_attendance ad"+
                " on ad.curdate like '%" + month + "%'"+
                " and al.userid = '" + userId + "' and ad.curdate between al.start_date and al.end_date"+
                " and al.type in ( 0,1,2,8,9 ) and ad.attendancestatus in (0,2)"+
                " order by curdate asc";
                 b.writeLog("请假明细:"+detailSql);
			 try {
                detail_rs.executeSql(detailSql);
                myDetailList = util.disassembleTableDataMapList(detail_rs);
             } catch (Exception e) {
                b.writeLog(e.getLocalizedMessage());
             }
            b.writeLog("请假集合:"+myDetailList);
 			if(myDetailList != null && myDetailList.size()>0){	
			%>
			<tr>		
				<th align='center'>请假日期</th>
				<th align='center'>请假（小时数）</th>
				<th align='center'>请假类型</th>
				<th align='center'>请假类别</th>
			</tr>
			<%
			   for (Map<String, String> detail : myDetailList) {	
                    String curdate = util.getFiled(detail,"请假日期");
                    String hourType = util.getFiled(detail,"请假小时类型");
                    String leaveType = util.getFiled(detail,"请假类型");
                    String leaveMark = util.getFiled(detail,"请假类别");
                    String start_time = util.getFiled(detail,"start_time");
                    String end_time = util.getFiled(detail,"end_time");
                    //请假小时
                    Double hour = 0.00;
                    DecimalFormat ndf = new DecimalFormat("#.00");
                    //层级判断
                   if(getDifferenceMins(start_time,end_time)>0){
                    if("单休周六上午".equals(leaveMark)){
                        if("当日".equals(hourType)){
                            //上午
                            if(getDifferenceMins(start_time,"11:45")>0){
                                out.println("<tr>");
                                out.println("<td align='center'>"+curdate+"</td>");
                                if(getDifferenceMins("11:45",end_time)>0){
                                    if(getDifferenceMins(start_time,"08:30")>0){
                                        out.println("<td align='center'>"+3.25+"</td>");
                                    }else {
                                        out.println("<td align='center'>"+getDifferenceHours(start_time,"11:45")+"</td>");
                                    }
                                }else{
                                    if(getDifferenceMins(start_time,"08:30")>0){
                                        out.println("<td align='center'>"+getDifferenceHours("08:30",end_time)+"</td>");
                                    }else {
                                        out.println("<td align='center'>"+getDifferenceHours(start_time,end_time)+"</td>");
                                    }
                                }
                                out.println("<td align='center'>"+leaveType+"</td>");
                                out.println("<td align='center'>单休周六上午</td>");
                                out.println("</tr>");
                            }
                            //下午
                            if(getDifferenceMins("13:00",end_time)>0){
                                out.println("<tr>");
                                out.println("<td align='center'>"+curdate+"</td>");
                                if(getDifferenceMins(end_time,"16:15")>0){
                                    if(getDifferenceMins(start_time,"13:00")>0){
                                        out.println("<td align='center'>"+getDifferenceHours("13:00",end_time)+"</td>");
                                    }else{
                                        out.println("<td align='center'>"+getDifferenceHours(start_time,end_time)+"</td>");
                                    }
                                }else{
                                    if(getDifferenceMins(start_time,"13:00")>0){
                                        out.println("<td align='center'>"+3.25+"</td>");
                                    }else{
                                        out.println("<td align='center'>"+getDifferenceHours(start_time,"16:15")+"</td>");
                                    }
                                }
                                out.println("<td align='center'>"+leaveType+"</td>");
                                out.println("<td align='center'>单休周六下午</td>");
                                out.println("</tr>");
                            }
                        }else if("中间日".equals(hourType)){
                            //上午
                            out.println("<tr>");
                            out.println("<td align='center'>"+curdate+"</td>");
                            out.println("<td align='center'>"+3.25+"</td>");
                            out.println("<td align='center'>"+leaveType+"</td>");
                            out.println("<td align='center'>单休周六上午</td>");
                            out.println("</tr>");
                            //下午
                            out.println("<tr>");
                            out.println("<td align='center'>"+curdate+"</td>");
                            out.println("<td align='center'>"+3.25+"</td>");
                            out.println("<td align='center'>"+leaveType+"</td>");
                            out.println("<td align='center'>单休周六下午</td>");
                            out.println("</tr>");
                        }
                        else if("开始日".equals(hourType)){
                            //上午
                            if(getDifferenceMins(start_time,"11:45")>0){
                                out.println("<tr>");
                                out.println("<td align='center'>"+curdate+"</td>");
                                if(getDifferenceMins(start_time,"08:30")>0){
                                    out.println("<td align='center'>"+3.25+"</td>");
                                }else {
                                    out.println("<td align='center'>"+getDifferenceHours(start_time,"11:45")+"</td>");
                                }
                                out.println("<td align='center'>"+leaveType+"</td>");
                                out.println("<td align='center'>单休周六上午</td>");
                                out.println("</tr>");
                            }
                            //下午
                            out.println("<tr>");
                            out.println("<td align='center'>"+curdate+"</td>");
                            if(getDifferenceMins(start_time,"13:00")>0){
                                out.println("<td align='center'>"+4.25+"</td>");
                            }else{
                                out.println("<td align='center'>"+getDifferenceHours(start_time,"16:15")+"</td>");
                            }
                            out.println("<td align='center'>"+leaveType+"</td>");
                            out.println("<td align='center'>单休周六下午</td>");
                            out.println("</tr>");
                        }
                        else if("结束日".equals(hourType)){
                            //上午
                            out.println("<tr>");
                            out.println("<td align='center'>"+curdate+"</td>");
                            if(getDifferenceMins("11:45",end_time)>0){
                                out.println("<td align='center'>"+3.25+"</td>");
                            }else{
                                out.println("<td align='center'>"+getDifferenceHours("08:30",end_time)+"</td>");
                            }
                            out.println("<td align='center'>"+leaveType+"</td>");
                            out.println("<td align='center'>单休周六上午</td>");
                            out.println("</tr>");
                            //下午
                            if(getDifferenceMins("13:00",end_time)>0){
                                out.println("<tr>");
                                out.println("<td align='center'>"+curdate+"</td>");
                                if(getDifferenceMins(end_time,"16:15")>0){
                                    out.println("<td align='center'>"+getDifferenceHours("13:00",end_time)+"</td>");
                                }else{
                                    out.println("<td align='center'>"+3.25+"</td>");
                                }
                                out.println("<td align='center'>"+leaveType+"</td>");
                                out.println("<td align='center'>单休周六下午</td>");
                                out.println("</tr>");
                            }
                        }

                    }else{
                        if("当日".equals(hourType)){
                             //上午
                          if(getDifferenceMins(start_time,"11:45")>0){
                             out.println("<tr>");
                             out.println("<td align='center'>"+curdate+"</td>");
                          if(getDifferenceMins("11:45",end_time)>0){	
                              if(getDifferenceMins(start_time,"08:30")>0){
                                  out.println("<td align='center'>"+3.25+"</td>");
                              }else {
                                  out.println("<td align='center'>"+getDifferenceHours(start_time,"11:45")+"</td>");
                              }
                          }else{
                         	 if(getDifferenceMins(start_time,"08:30")>0){
                         	  out.println("<td align='center'>"+getDifferenceHours("08:30",end_time)+"</td>");
                         	 }else {
                         	  out.println("<td align='center'>"+getDifferenceHours(start_time,end_time)+"</td>");
                         	 }
						    }
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日上午</td>");
                             out.println("</tr>"); 
                            }                   
                             //下午
                            if(getDifferenceMins("13:00",end_time)>0){
                             out.println("<tr>");
						     out.println("<td align='center'>"+curdate+"</td>");
						     if(getDifferenceMins(end_time,"17:15")>0){
						  	  if(getDifferenceMins(start_time,"13:00")>0){
						  	    out.println("<td align='center'>"+getDifferenceHours("13:00",end_time)+"</td>");
						      }else{
						        out.println("<td align='center'>"+getDifferenceHours(start_time,end_time)+"</td>");
						      }
						     }else{
						       if(getDifferenceMins(start_time,"13:00")>0){
						  	    out.println("<td align='center'>"+4.25+"</td>");						  	 
						      }else{
						        out.println("<td align='center'>"+getDifferenceHours(start_time,"17:15")+"</td>");						     
						      }
						     }
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日下午</td>");
                             out.println("</tr>");
                             }                   
 					  }else if("中间日".equals(hourType)){
 					        //上午
                            out.println("<tr>");
 					      	out.println("<td align='center'>"+curdate+"</td>");
							out.println("<td align='center'>"+3.25+"</td>");
							out.println("<td align='center'>"+leaveType+"</td>");
							out.println("<td align='center'>工作日上午</td>");
                            out.println("</tr>");
                            //下午
                            out.println("<tr>");
 					      	out.println("<td align='center'>"+curdate+"</td>");
							out.println("<td align='center'>"+4.25+"</td>");
							out.println("<td align='center'>"+leaveType+"</td>");
							out.println("<td align='center'>工作日下午</td>");
                            out.println("</tr>"); 
 					  }
 					  else if("开始日".equals(hourType)){                    
                             //上午
                          if(getDifferenceMins(start_time,"11:45")>0){
                             out.println("<tr>");
                             out.println("<td align='center'>"+curdate+"</td>");
                         	 if(getDifferenceMins(start_time,"08:30")>0){
                         	  out.println("<td align='center'>"+3.25+"</td>");                         	 
                         	 }else {
                         	  out.println("<td align='center'>"+getDifferenceHours(start_time,"11:45")+"</td>");                        	 
                         	 }						      
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日上午</td>");
                             out.println("</tr>"); 
                            }                   
                             //下午
                             out.println("<tr>");
						     out.println("<td align='center'>"+curdate+"</td>");
						     if(getDifferenceMins(start_time,"13:00")>0){
						  	   out.println("<td align='center'>"+4.25+"</td>");						  	 
						      }else{
						       out.println("<td align='center'>"+getDifferenceHours(start_time,"17:15")+"</td>");						     
						      }
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日下午</td>");
                             out.println("</tr>");                         
 					  } 
 					  else if("结束日".equals(hourType)){
                            //上午
                             out.println("<tr>");
                             out.println("<td align='center'>"+curdate+"</td>");
                          if(getDifferenceMins("11:45",end_time)>0){	
						      out.println("<td align='center'>"+3.25+"</td>");
						    }else{
                         	  out.println("<td align='center'>"+getDifferenceHours("08:30",end_time)+"</td>");                         	 
						    }
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日上午</td>");
                             out.println("</tr>");                   
                             //下午
                            if(getDifferenceMins("13:00",end_time)>0){
                             out.println("<tr>");
						     out.println("<td align='center'>"+curdate+"</td>");
						     if(getDifferenceMins(end_time,"17:15")>0){
						  	    out.println("<td align='center'>"+getDifferenceHours("13:00",end_time)+"</td>");
						     }else{
						  	    out.println("<td align='center'>"+4.25+"</td>");						  	 
						     }
						     out.println("<td align='center'>"+leaveType+"</td>");
						     out.println("<td align='center'>工作日下午</td>");
                             out.println("</tr>");
                             }
 					  }                   
                     }
                    }
 				}
			}else{
				out.println("<tr>");
				out.println("<th colspan='9' style='font-size:18px;height:80px;' align='center'>无查询结果，请确认查询报表条件</td>");
				out.println("</tr>");
			}
			%>
            <!--将时间转换成int类型-->
            <%!
                public static int getTimeMin(String curTime, int index) {
                    int minute = Integer.parseInt(curTime.split(":")[index]);
                    return minute;
                }
            %>
            <!--计算两个时间相差的小时数(保留一位小数)-->
            <%!
                public static String getDifferenceHours(String startTime,String endTime){
                    DecimalFormat df=new DecimalFormat("0.00");
                    int firstSignForMin1=getTimeMin(startTime,0)*60+getTimeMin(startTime,1);//第一次打卡对应的分钟数
                    int secondSignForMin1=getTimeMin(endTime,0)*60+getTimeMin(endTime,1);//第二次打卡对应的分钟数
                    String differenceHours=df.format((float)(secondSignForMin1-firstSignForMin1)/60);
                    return differenceHours;
                }
            %>
            <!--计算两个时间相差的分钟数-->
            <%!
                public static Integer getDifferenceMins(String startTime,String endTime){
                    int firstSignForMin1=getTimeMin(startTime,0)*60+getTimeMin(startTime,1);//第一次打卡对应的分钟数
                    int secondSignForMin1=getTimeMin(endTime,0)*60+getTimeMin(endTime,1);//第二次打卡对应的分钟数
                    int differencMins=secondSignForMin1-firstSignForMin1;
                    return differencMins;
                }
            %>
		</table>
</table>
</body>
</html>
