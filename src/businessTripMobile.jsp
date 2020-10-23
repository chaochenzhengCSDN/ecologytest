<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@page import="weaver.general.Util"%>
<%@page import="weaver.conn.RecordSet"%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<head>
	<script type="text/javascript">
	  /* 测试环境 */
	  /*
      var userid_field = "#field153199";        	// 出差申请人id
      var startDate_field = "#field153213";     	// 出差开始日期
      var endDate_field = "#field153215";       	// 出差结束日期
      var select_start_field = "#field153214";  	// 选择开始时间
      var select_end_field = "#field153216";    	// 选择结束时间
      var business_days_field = "#field153209";     // 出差天数
       */
		/* 正式环境 */
		var userid_field = "#field216597";        // 出差申请人id
		var startDate_field = "#field216603";     // 出差开始日期
		var endDate_field = "#field216605";       // 出差结束日期
		var select_start_field = "#field216604";  // 选择开始时间
		var select_end_field = "#field216606";    // 选择结束时间
		var business_days_field = "#field216607"; // 出差天数

		jQuery(document).ready(function () {
			//流程提交前
			checkCustomize = function () {
				var bool = true;
				var userid = $(userid_field).val();//申请人id
				var startDate = $(startDate_field).val();//出差开始日期
				var endDate = $(endDate_field).val();//出差结束日期
				var checkThreeDaysAgoMsg = checkThreeDaysAgo();//三天前校验
				if (checkThreeDaysAgoMsg != "1") {
					alert(checkThreeDaysAgoMsg);
					bool = false;
				}
				//判断是否在出差日期之间提交
				if (bool) {
					jQuery.ajax({
						type: "POST",
						cache: false,
						async: false,
						url: "/iiot/grouptow/processValidation/businessTrip_ajax.jsp?action=isRepeat&userid=" + userid + "&startDate=" + startDate + "&endDate=" + endDate,
						success: function (str) {
							var json = eval('(' + str + ')');
							if (bool && json.count == 1) {
								alert(json.message);
								bool = false;
							}
						}
					});
				}
				if (bool) {
					bool = checkDate("checkCustomize");
				}
				return bool;
			}
		});
		//选择开始日期
		jQuery(startDate_field).bindPropertyChange(function (obj) {
			checkDate();
		});
		//选择开始时间
		jQuery(select_start_field).bindPropertyChange(function (obj) {
			checkDate();
		});
		//选择结束日期
		jQuery(endDate_field).bindPropertyChange(function (obj) {
			checkDate();
		});
		//选择结束时间
		jQuery(select_end_field).bindPropertyChange(function (obj) {
			checkDate();
		});

		/** 排班 (0:出勤 1:不出勤) (0:节假日 1:不是节假日) */
		function checkDate() {
			var days1;//查询出差开始日期到出差结束日期期间（除了起始日期和结束日期当天）有几天是工作日
			var days2;//查询出差开始日期到出差结束日期期间（除了起始日期和结束日期当天）有几天是非工作日(包含法定假日，周六单休，周末放假)
			var attendancestatus1;//出差开始当天是否为工作日start
			var attendancestatus2;//出差结束当天是否为工作日end
			var week1;//出差开始当天为周几
			var week2;//出差结束当天为周几
			var startTime = $(select_start_field).val();//出差开始时间
			var startTimes = startTime.split(":");//计算出差开始时间分钟数
			var startTimeMinutes = parseInt(startTimes[0] * 60) + parseInt(startTimes[1]);
			var endTime = $(select_end_field).val();//出差结束时间
			var endTimes = endTime.split(":"); //计算出差结束时间分钟数
			var endTimeMinutes = parseInt(endTimes[0] * 60) + parseInt(endTimes[1]);
			var startDate = $(startDate_field).val(); //出差开始日期
			var endDate = $(endDate_field).val();	  //出差结束日期
			var bool = true;
			jQuery.ajax({
				type: "POST",
				cache: false,
				async: false,
				url: "/iiot/grouptow/processValidation/businessTrip_ajax.jsp?action=checkDate&startDate=" + startDate + "&endDate=" + endDate,
				success: function (str) {
					var json = eval("(" + str + ")");
					//代码块
					days1 = parseInt(json.attendanceDays1);
					days2 = parseInt(json.attendanceDays2);
					attendancestatus1 = parseInt(json.attendancestatus1);
					attendancestatus2 = parseInt(json.attendancestatus2);
					week1 = parseInt(json.week1);
					week2 = parseInt(json.week2);
				}
			});
			//出差开始到出差结束相差多少小时
			var times;
			//计算日期间隔
			var startDateTimes = Date.parse(startDate);
			var endDateTimes = Date.parse(endDate);
			var dateTimes = Math.abs(endDateTimes - startDateTimes);
			//加班参数
			var overtime_start = startTimeMinutes; //加班开始
			var overtime_end = endTimeMinutes;     //加班结束
			//判断是否为同一天
			if (dateTimes == 0) {
				/*
					1.定义数据为固定值
						1.开始时间小于上午上班时间
						2.开始时间大于下午下班时间
						3.结束时间小于上午上班时间
						4.结束时间大于下午下班时间
					2.判断时间点
						1.开始时间和结束时间都在上午上班期间
						2.开始时间和结束时间都在下午上班期间
						3.开始时间在上午上班期间，结束时间在下午上班期间
				*/
				//  开始时间距离8点半的时间差
				if (startTimeMinutes <= (8 * 60 + 30)) {
					startTimeMinutes = 0;
				} else if (startTimeMinutes > (8 * 60 + 30) && startTimeMinutes <= 11 * 60 + 45) {
					startTimeMinutes = startTimeMinutes - 8 * 60 - 30;
				} else if (startTimeMinutes > (11 * 60 + 45) && startTimeMinutes <= 13 * 60) {
					startTimeMinutes = 11 * 60 + 45 - 8 * 60 - 30;
				} else if (startTimeMinutes > (13 * 60) && startTimeMinutes <= 17 * 60 + 15) {
					startTimeMinutes = startTimeMinutes - 8 * 60 - 30 - 75;
				} else {
					startTimeMinutes = 0;
				}
				//结束时间距离8点半的时间差
				if (endTimeMinutes <= (8 * 60 + 30)) {
					endTimeMinutes = 0;
				} else if (endTimeMinutes > (8 * 60 + 30) && endTimeMinutes <= 11 * 60 + 45) {
					endTimeMinutes = endTimeMinutes - 8 * 60 - 30;
				} else if (endTimeMinutes > (11 * 60 + 45) && endTimeMinutes <= 13 * 60) {
					endTimeMinutes = 11 * 60 + 45 - 8 * 60 - 30;
				} else if (endTimeMinutes > (13 * 60) && endTimeMinutes <= 17 * 60 + 15) {
					endTimeMinutes = endTimeMinutes - 8 * 60 - 30 - 75;
				} else {
					endTimeMinutes = 7.5 * 60;
				}
				times = (endTimeMinutes - startTimeMinutes) / 60;// 正常工作日计算
			} else {
				//出差开始当天多少小时
				var time1;
				//出差期间多少小时(不包括出差开始当天和出差结束当天)
				var time2;
				//出差结束当天多少小时
				var time3;
				//计算出差开始当天多少小时
				/*
					1.出差开始时间在上午上班之前(00:00-08:30)
					2.出差开始时间在上午上班期间(08:30-11:45)
					3.出差开始时间在中午午休期间(11:45-13:00)
					4.出差开始时间在下午上班期间(13:00-17:15)
					5.出差开始时间在下午下班之后(17:15-23:59)
				*/
				if (startTimeMinutes <= (8 * 60 + 30)) {
					time1 = 7.5;
				} else if (startTimeMinutes < (11 * 60 + 45) && startTimeMinutes > (8 * 60 + 30)) {
					time1 = ((11 * 60 + 45) - startTimeMinutes) / 60 + 4.25;
				} else if (startTimeMinutes == (11 * 60 + 45)) {
					time1 = 3.25;
				} else if (startTimeMinutes > (11 * 60 + 45) && startTimeMinutes <= (13 * 60)) {
					time1 = 3.25;
				} else if (startTimeMinutes > 13 * 60 && startTimeMinutes < (17 * 60 + 15)) {
					time1 = ((17 * 60 + 15) - startTimeMinutes) / 60;
				} else if (startTimeMinutes == (17 * 60 + 15)) {
					time1 = 4.25;
				} else {
					time1 = 0;
				}

				//计算出差期间多少小时(不包括出差开始当天和出差结束当天)
				time2 = days1 * 7.5 + days2 * 7.5;
				//计算出差结束当天多少小时
				/*
					1.出差结束时间在上午上班之前(00:00-08:30)
					2.出差结束时间在上午上班期间(08:30-11:45)
					3.出差结束时间在中午午休期间(11:45-13:00)
					4.出差结束时间在下午上班期间(13:00-17:15)
					5.出差结束时间在下午下班之后(17:15-23:59)
				*/
				if (endTimeMinutes <= (8 * 60 + 30)) {
					time3 = 0;
				} else if (endTimeMinutes < (11 * 60 + 45) && endTimeMinutes > (8 * 60 + 30)) {
					time3 = (endTimeMinutes - (8 * 60 + 30)) / 60;
				} else if (endTimeMinutes == (11 * 60 + 45)) {
					time3 = 3.25;
				} else if (endTimeMinutes > (11 * 60 + 45) && endTimeMinutes <= (13 * 60)) {
					time3 = 3.25;
				} else if (endTimeMinutes > 13 * 60 && endTimeMinutes < (17 * 60 + 15)) {
					time3 = (endTimeMinutes - (13 * 60)) / 60 + 3.25;
				} else if (endTimeMinutes == (17 * 60 + 15)) {
					time3 = 7.5;
				} else {
					time3 = 7.5;
				}
				//加班开始时间
				if (attendancestatus1 == 1 || attendancestatus1 == 2) { // 非出勤 或者 周六半日出勤
					if (overtime_start != "" && overtime_start > 0 && overtime_start < 24 * 60) {
						time1 = (24 * 60 - overtime_start) / 60;
						if (time1 > 7.5) {
							time1 = 7.5;
						}
					}
				}
				//加班结束时间
				if (attendancestatus2 == 1 || attendancestatus2 == 2) { // 非出勤 或者 周六半日出勤
					if (overtime_end != "" && overtime_end > 0 && overtime_start < 24 * 60) {
						time3 = overtime_end / 60;
						if (time3 > 7.5) {
							time3 = 7.5;
						}
					}
				}
				times = time1 + time2 + time3;
			}
			//判断出差开始是否大于出差结束
			if (endDate >= startDate && times >= 0.5 && startDate != "" && endDate != "" && startTime != "" && endTime != "") {
				$(business_days_field).val(Math.round((times / 7.5) * 10) / 10);
			}
            if ( startDate != "" && endDate != "" && startTime != "" && endTime != "" && (startDate > endDate || (startDate == endDate && startTime > endTime))) {
				$(business_days_field).val(0);
				alert("截止时间不能早于开始时间");
				bool = false;
			} else if ( startDate != "" && endDate != "" && startTime != "" && endTime != "" && (startDate < endDate || (startDate == endDate && startTime <= endTime)) && times < 0.5) {
				$(business_days_field).val(0);
				alert("出差小时数不能小于0.5h");
				bool = false;

			}
			$(business_days_field).attr("readOnly", "readOnly"); //只读
			return bool;
		}

		/*检测提交日期是否在3天之内*/
		function checkThreeDaysAgo() {
			var date = new Date();
			date.setDate(date.getDate() - 3);
			var month = date.getMonth() + 1;
			var day = date.getDate();
			month = (month < 10) ? ("0" + month) : month;
			day = (day < 10) ? ("0" + day) : day;
			var minDate = date.getFullYear() + '-' + month + '-' + day;
			var startDate = $(startDate_field).val(); //出差开始日期
			if (startDate != "") {
				if (startDate < minDate) {
					return "申请已超过3天有效期";
				} else {
					return "1";
				}
			}
		}
	</script>
</head>

</html>