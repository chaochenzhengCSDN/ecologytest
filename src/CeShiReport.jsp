<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ include file="/systeminfo/init_wev8.jsp" %>
<%@page import="java.text.SimpleDateFormat"%>
<%@ page import="java.io.Console" %>
<%@ taglib uri="/WEB-INF/weaver.tld" prefix="wea"%>
<%@ taglib uri="/browserTag" prefix="brow"%>
<jsp:useBean id="BaseBean" class="weaver.general.BaseBean" scope="page" />
<jsp:useBean id="DepartmentComInfo" class="weaver.hrm.company.DepartmentComInfo" scope="page"/>
<%
String _staffName = Util.null2String(request.getParameter("staffName"));

/**
 * 获取上一个月的信息 年月
 */
SimpleDateFormat format = new SimpleDateFormat("yyyy-MM");
Date date = new Date();
Calendar calendar = Calendar.getInstance();
// 设置为当前时间
calendar.setTime(date);
// 设置为上一个月
calendar.set(Calendar.MONTH, calendar.get(Calendar.MONTH) - 1);
date = calendar.getTime();
String accDate = format.format(date);
String year =accDate.split("-")[0];
String month =accDate.split("-")[1];
%> 
<html>
<head>
	<script language="javascript" src="/js/weaver_wev8.js"></script>
	<script language="javascript" src="/js/weaverTable_wev8.js"></script>
	<script>
		function ajaxinit(){
			var ajax=false;
			try {
				ajax = new ActiveXObject("Msxml2.XMLHTTP");
			} catch (e) {
				try {
					ajax = new ActiveXObject("Microsoft.XMLHTTP");
				} catch (E) {
					ajax = false;
				}
			}
			if (!ajax && typeof XMLHttpRequest!='undefined') {
				ajax = new XMLHttpRequest();
			}
			return ajax;
		}
		function showdata(){
			jQuery(".wait-hide").addClass('wait');
			//获取年份的值
			var year = jQuery("#year").val();
			//获取月份的值
			var month = jQuery("#month").val();
			//获取人员id
			var staffName = jQuery("#staffName").val();
			var ajax=ajaxinit();
			ajax.open("POST", "CeShiWorkReport.jsp", true);
			ajax.setRequestHeader("Content-Type","application/x-www-form-urlencoded");			
			ajax.send("month=" + year + "-" + month + "&staffName=" + staffName + "&companyId=761");
			//获取执行状态
			ajax.onreadystatechange = function() {
				//如果执行状态成功，那么就把返回信息写到指定的层里
				if (ajax.readyState == 4 && ajax.status == 200) {
					try{						
						document.all("showdatadiv").innerHTML=ajax.responseText;
					}catch(e){
						return false;
					}
				}
				jQuery(".wait-hide").removeClass('wait');
			}
		}
		var dialog = null;
		var dWidth = 1000;
		var dHeight = 500;		
		function todo(url,title,_dWidth,_dHeight){
			if(dialog==null){
				dialog = new window.top.Dialog();
			}
			dialog.currentWindow = window;
			dialog.Title = title;
			dialog.Width = _dWidth ? _dWidth : dWidth;
			dialog.Height = _dHeight ? _dHeight : dHeight;
			dialog.Drag = true;
			dialog.maxiumnable = true;
			dialog.URL = url;
			dialog.show();
		}
		function doExcel(){			
			var year = jQuery("#year").val();
			var month = jQuery("#month").val();
			//员工id
			var staffName = jQuery("#staffName").val();
			window.location.href = "CeShiWorkReportToExcel.jsp?month=" + year + "-" + month + "&staffName=" + staffName + "&companyId=761";
		}
	</script>
	<style type="text/css">
	*{
		margin: 0;
		padding: 0;
		border: 0;
		list-style-type: none;
		font-size: 11px;
	}
	td,th{
		border-bottom: 1px solid #90BADD;
		border-right: 1px solid #90BADD;
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
	.wait-hide{
		display:none;
	}
	body .wait{
		display: flex;
		justify-content: center;
		align-items: center;
		flex-direction: column;
		width: 100%;
		height: 100%;
		position: fixed;
		z-index: 99999;
		background: rgba(0,0,0,0.6);
	}
	.wait img{
		width: 100px;
		height: 100px;
		margin-bottom: 20px;
	}
	.wait p{
		font-size: 16px;
		color: #fff;
	}
	</style>
</head>
<body>
<div class="wait-hide">
	<img src="/shopwork/img/loading.gif">
	<p>报表生成中，请稍后。。。</p>
</div>
<%@ include file="/systeminfo/RightClickMenuConent_wev8.jsp" %>
<%
RCMenu += "{导出Excel,javaScript:doExcel(),_self}";
RCMenuHeight += RCMenuHeightStep;
%>
<%@ include file="/systeminfo/RightClickMenu_wev8.jsp" %>
	<wea:layout>
		<wea:group context='<%=SystemEnv.getHtmlLabelName(15505,user.getLanguage())%>'>
			<wea:item>
			<table style="width:100%;" border="0" cellpadding="0" cellspacing="0">
				<tr style="width: 100%;">
					<td style="text-align: right;border-right: 0;border-bottom: 1px solid #90BADD;width: 400px;height: 40px;">年月：</td>
					<td colspan="1" style="text-align: left;border-right: 0;border-bottom: 1px solid #90BADD;height: 30px;width:500px;">
						<select id="year" name="year" style="width: 50px;">
							<option value="2019" <%=year.equals("2019")?"selected":"" %>>2019</option>
							<option value="2020" <%=year.equals("2020")?"selected":"" %>>2020</option>
							<option value="2021" <%=year.equals("2021")?"selected":"" %>>2021</option>
							<option value="2022" <%=year.equals("2022")?"selected":"" %>>2022</option>
							<option value="2023" <%=year.equals("2023")?"selected":"" %>>2023</option>
							<option value="2024" <%=year.equals("2024")?"selected":"" %>>2024</option>
							<option value="2025" <%=year.equals("2025")?"selected":"" %>>2025</option>
						</select>——
						<select id="month" style="width: 50px;">
							<option value="01" <%=month.equals("01")?"selected":"" %>>01</option>
							<option value="02" <%=month.equals("02")?"selected":"" %>>02</option>
							<option value="03" <%=month.equals("03")?"selected":"" %>>03</option>
							<option value="04" <%=month.equals("04")?"selected":"" %>>04</option>
							<option value="05" <%=month.equals("05")?"selected":"" %>>05</option>
							<option value="06" <%=month.equals("06")?"selected":"" %>>06</option>
							<option value="07" <%=month.equals("07")?"selected":"" %>>07</option>
							<option value="08" <%=month.equals("08")?"selected":"" %>>08</option>
							<option value="09" <%=month.equals("09")?"selected":"" %>>09</option>
							<option value="10" <%=month.equals("10")?"selected":"" %>>10</option>
							<option value="11" <%=month.equals("11")?"selected":"" %>>11</option>
							<option value="12" <%=month.equals("12")?"selected":"" %>>12</option>
						</select>
					</td>
					<td colspan="1" style="text-align: right;border-right: 0;border-bottom: 1px solid #90BADD;width: 80px;">人员名称：</td>
					<td colspan="4" style="text-align: left;border-right: 0;border-bottom: 1px solid #90BADD;width: 200px;">
						<brow:browser viewType="0" name="staffName" browserValue="<%=_staffName%>"
							browserUrl="/systeminfo/BrowserMain.jsp?url=/hrm/resource/ResourceBrowser.jsp"
							hasInput="true" isSingle="false" hasBrowser = "true" isMustInput='1'
							completeUrl="/data.jsp?type=4" width="90%" >
						</brow:browser>
					</td>
					<td colspan="1" style="text-align: left;border-right: 0;border-bottom: 1px solid #90BADD;width: 100px;">
						<input id="showDataButton" type="button" value="查询" onclick="showdata()" class="middle e8_btn_top_first" />
					</td>
				</tr>
			</table>	
			</wea:item>
		</wea:group>
	</wea:layout>
	<wea:layout>
		<wea:group context='<%=SystemEnv.getHtmlLabelNames("15101,356",user.getLanguage())%>'>
			<wea:item>
				<div id="showdatadiv" style="width:97%;"></div>
			</wea:item>
		</wea:group>
	</wea:layout>
</body>
</html>