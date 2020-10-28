<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@page import="weaver.general.Util"%>
<%@page import="weaver.conn.RecordSet"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<head>
	<script type="text/javascript">
		/* 正式环境 */
		var userIdfield = "#field23143";//申请人
		var applicationDatefield = "#field23146";//申请日期
		var valuefield = "#field23147";//请假类型
		var annualHoursfield = "#field215017";//可用年假天数
		var relaxHoursfield = "#field215018";//可用调休小时数
		var startDatefield = "#field23148";//起始日期
		var endDatefield = "#field23150";//截止日期
		var startTimefield = "#field23149";//起始时间
		var endTimefield = "#field23151";//截止时间
		var hoursfield = "#field23153";//请假小时数
		var daysfield = "#field26207";//请假天数
		var deadlineId ="#field227518" ;//截至日期
		var deadlinespanId ="#field227518span" ;//截至日期
		var userId = $(userIdfield).val();//姓名
		var applicationDate = $(applicationDatefield).val();//申请日期
		var wholeHours;//总小时数
		var annualHours1;
		//页面加载完
		jQuery(document).ready(function () {
			var applicationDate = $(applicationDatefield).val();//申请日期
			//获取年假数据
			getAnnualTime();
			//流程提交前
			checkCustomize = function () {
				var bool = true;
				//使用假期优先规则 调休--年假--事假
				var value = $(valuefield).val();//请假类型
				var annualHours = $(annualHoursfield).val();//可用年假小时数
				var relaxHours = $(relaxHoursfield).val();//可用调休小时数
				var startDate = $(startDatefield).val();//起始日期
				var endDate = $(endDatefield).val();//截止日期
				var startTime = $(startTimefield).val();//起始时间
				var endTime = $(endTimefield).val();//截止时间

				//console.log("调休小时数:" + relaxHours);
				if (startDate != "") {
					//bool = getBeforeDate();//申请日期3天前校验
					// if (!bool) {
					// 	return bool;
					// }
					//如果是调休申请，只能申请当月2020.07.08
					if(value==8){
						if(applicationDate.substring(0,7)<startDate.substring(0,7)||applicationDate.substring(0,7)<endDate.substring(0,7)){
							window.top.Dialog.alert("调休只能申请当月");
							bool =false;
							return bool;
						}
					}
				}
				if (wholeHours >= 1) {

					//请假类型为年休假 value=0
					if (value == 0) {
						//请假小时数小于等与调休小时数
						if (Number(wholeHours) <= Number(relaxHours)) {
							window.top.Dialog.alert("调休假时长充足，请切换成调休假");
							bool = false;
							return bool;
						}else{
							if (Number($(annualHoursfield).val()) < Number($(daysfield).val())) {
								window.top.Dialog.alert("可用年休假时长不足，请切换事假");
								bool = false;
								return bool;
							}
						}
						//请假类型为调休 value=8
					} else if (value == 8) {
						//如果请假小时数大于可用调休小时数 提示可用调休时长不足，请切换年休假或事假
						//console.log("checkCustomize -> wholeHours", wholeHours)
						//console.log("checkCustomize -> relaxHours", relaxHours)
						//console.log("checkCustomize -> wholeHours > relaxHours", wholeHours > relaxHours)
						if (Number(wholeHours) > Number(relaxHours)) {
							//请假小时数大于年假小时数
							if (Number(wholeHours) > Number(annualHours1)) {
								//console.log(annualHours1);
								//console.log(1231);
								window.top.Dialog.alert("可用调休时长不足，请切换事假");
								bool = false;
								return bool;
							} else {
								//请假小时数小于等于年假小时数 大于调休小时数
								window.top.Dialog.alert("可用调休时长不足，请切换年休假");
								bool = false;
								return bool;
							}
						}
						//请假类型为事假 value=9
					} else if (value == 9) {
						//如果请假为事假 请假小时数小于等于调休小时数
						if (Number(wholeHours) <= Number(relaxHours)) {
							window.top.Dialog.alert("调休假时长充足，请切换成调休假");
							bool = false;
						} else {
							//如果请假为事假 请假小时数大于调休小时数 请假小时数小于等于年假小时数
							if (Number(wholeHours) <= Number(annualHours1)) {
								window.top.Dialog.alert("年休假时长充足，请切换成年休假");
								bool = false;
								return bool;
							}
						}
						//请假类型为其他类型
					} else {
						//请假小时数小于可用调休小时数
						if (Number(wholeHours) <= Number(relaxHours)) {
							window.top.Dialog.alert("调休假时长充足，请切换成调休假");
							bool = false;
							return bool;
						} else {
							//请假小时数大于可用调休小时数 但小于等于年假小时数
							if (Number(wholeHours) <= Number(annualHours1)) {
								window.top.Dialog.alert("年休假时长充足，请切换成年休假");
								bool = false;
								return bool;
							}
						}
					}
				} else if ((wholeHours < 1) || (startDate == endDate && startTime > endTime) || (startDate > endDate)) {
					//请假小时数小于1小时或 开始日期结束日期在同一天 开始时间大于结束时间
					if ((startDate == endDate && startTime > endTime) || (startDate > endDate)) {
						// 开始日期结束日期在同一天 开始时间大于结束时间
						window.top.Dialog.alert("截止时间不能早于开始时间");
						bool = false;
						return bool;
					} else if (startDate <= endDate && startTime <= endTime && wholeHours < 1) {
						//请假小时数小于1小时
						window.top.Dialog.alert("请假申请1小时起请");
						bool = false;
						return bool;
					}
				}


				//判断是否在请假日期之间提交
				if (bool) {
					if (startDate != "" && endDate != "" && startDate != endDate) {
						jQuery.ajax({
							type: "POST",
							cache: false,
							async: false,
							url: "/iiot/grouptow/processValidation/leave_ajax.jsp?action=getDuplicateRecords&userid=" + userId + "&startDate=" + startDate + "&endDate=" + endDate + "&startTime=" + startTime + "&endTime=" + endTime,
							success: function (str) {
								var json = eval('(' + str + ')');
								if (bool && json.count == 1) {
									window.top.Dialog.alert(json.message);
									bool = false;
									return bool;
								}
							}
						});
					}
				}
				return bool;
			}
		});

		/*
			在请假类型、起始日期、起始时间、截止日期、截止时间添加绑定事件
			获取请假天数和请假小时数
		*/
		jQuery(valuefield).bindPropertyChange(function () {
			checkDate();
		});
		jQuery(startDatefield).bindPropertyChange(function () {
			checkDate();
		});
		jQuery(startTimefield).bindPropertyChange(function () {
			checkDate();
		});
		jQuery(endDatefield).bindPropertyChange(function () {
			checkDate();
			//根据截至日期获取两天后的日期来控制流程流转 2020-10-09 zcc
			var endDate = $(endDatefield).val();//截止日期
			$(deadlineId).val(getAfterDate(endDate));
			$(deadlinespanId).html(getAfterDate(endDate));
		});
		jQuery(endTimefield).bindPropertyChange(function () {
			checkDate();
		});


		/*
			根据申请日期applicationDate和姓名userId获取年假数据
		*/
		function getAnnualTime() {
			var year = applicationDate.substring(0, 4);
			jQuery.ajax({
				type: "POST",
				cache: false,
				async: false,
				data: { "userId": userId, "year": year },
				url: "/iiot/grouptow/processValidation/leave_ajax.jsp?action=getAnnualTime&userId=" + userId + "&year=" + year + "&applicationDate=" + applicationDate,
				success: function (str) {
					var res = eval("(" + str + ")");
					//获取年假天数
					annualHours1 = res.ableHours;
					jQuery(annualHoursfield).val(res.ableHours);
					jQuery(annualHoursfield+"span").html(res.ableHours);
					jQuery(annualHoursfield+"_span").html(res.ableHours);
					//获取可调休小时数
					//console.log("可调休小时数:" + res.overtimeHours);
					jQuery(relaxHoursfield).val(res.overtimeHours);
					jQuery(relaxHoursfield+"span").html(res.overtimeHours);
					jQuery(relaxHoursfield+"_span").html(res.overtimeHours);
				}
			});
		};

		/*
			比较日期
		*/
		function checkDate() {
			var isWorktime1;//开始时间
			var isWorktime2;//结束时间
			var startWeek;//开始日期对应的星期几
			var endWeek;//结束日期对应的星期几
			var isAttendance;//是否出勤
			var days;//请假对应的天数

			var startTime3;//距离早上8：30的小时数
			var startDate = $(startDatefield).val();//起始日期
			var endDate = $(endDatefield).val();//截止日期
			var startTime = $(startTimefield).val();//起始时间
			var endTime = $(endTimefield).val();//截止时间
			var value = $(valuefield).val();//请假类型
			var res = startTime !== "" && endTime !== "" && startDate !== "" && endDate !== "" &&((startDate === endDate && startTime < endTime) || (startDate < endDate));
			//改变所选时间
			if(value===0){
				var startTimeChange1 = startTime.split(":");
				var startTimeChange2 = parseInt(startTimeChange1[0] * 60) + parseInt(startTimeChange1[1]);
				if (startTimeChange2 < (11 * 60 + 45)) {
					jQuery(startTimefield).val("08:30");
					jQuery(startTimefield+"span").html("08:30");
					jQuery(startTimefield+"_span").html("08:30");
				} else if (startTimeChange2 > (11 * 60 + 45)) {
					jQuery(startTimefield).val("13:00");
					jQuery(startTimefield+"span").html("13:00");
					jQuery(startTimefield+"_span").html("13:00");
				}
				var endTimeChange1 = endTime.split(":");
				var endTimeChange2 = parseInt(endTimeChange1[0] * 60) + parseInt(endTimeChange1[1]);
				if (endTimeChange2 < (13 * 60)) {
					jQuery(endTimefield).val("11:45");
					jQuery(endTimefield+"span").html("11:45");
					jQuery(endTimefield+"_span").html("11:45");
				} else if (endTimeChange2 > (13 * 60)) {
					jQuery(endTimefield).val("17:15");
					jQuery(endTimefield+"span").html("17:15");
					jQuery(endTimefield+"_span").html("17:15");
				}
			}

			if (startTime !== "" && endTime !== "" && startDate !== "" && endDate !== "" &&((startDate === endDate && startTime < endTime) || (startDate < endDate))) {
				jQuery.ajax({
					type: "POST",
					cache: false,
					async: false,
					url: "/iiot/grouptow/processValidation/leave_ajax.jsp?action=getAttendanceTime&userId=" + userId + "&endDate=" + endDate + "&startDate=" + startDate  + "&endTime=" + endTime + "&startTime=" + startTime,//获取开始日期结束日期对应是否为工作日，星期几以及调休小时数
					success: function (str) {
						var json = eval("(" + str + ")");
						//获取年假天数
						jQuery(annualHoursfield).val(json.ableHours);
						jQuery(annualHoursfield+"span").html(json.ableHours);
						jQuery(annualHoursfield+"_span").html(json.ableHours);
						//获取可调休小时数
						jQuery(relaxHoursfield).val(json.wholeOvertimehours);
						jQuery(relaxHoursfield+"span").html(json.wholeOvertimehours);
						jQuery(relaxHoursfield+"_span").html(json.wholeOvertimehours);
						wholeHours = json.wholeLeaveHours;
						$(hoursfield).val(wholeHours);
						$(hoursfield + "span").html(wholeHours);
						$(hoursfield).attr("readonly", "readonly");
						$(hoursfield + "span").attr("style", "display:none;");
					}
				});
				if(value==0){
					//请假天数
					/**
					 1、3.25为0.5天
					 2、4.23也为0.5天
					 */
							//向下取整数，比如7.5，向下取整就是7
					var leaveDays = Math.floor(wholeHours / 7.5);
					//计算小时数，总的小时数-向下取整*7.5 = 多余的小时数
					var leaveHours = wholeHours - (7.5 * leaveDays);
					if (leaveHours < 5 && leaveHours > 0) {
						leaveDays += 0.5;
					} else if (leaveHours > 5) {
						leaveDays += 1.0;
					}
				}else{
					leaveDays = wholeHours / 7.5;
				}
				$(daysfield).val((Math.round(leaveDays * 10 ))/10);
				$(daysfield + "span").html((Math.round(leaveDays * 10)) / 10);
				$(daysfield).attr("readonly", "readonly");
				$(daysfield + "span").attr("style", "display:none;");

			}else if (startTime != "" && endTime != "" && startDate != "" && endDate != "" &&((startDate == endDate && startTime > endTime) || (startDate > endDate))){
				wholeHours = 0;
				$(hoursfield).val(wholeHours);
				$(hoursfield + "span").html(wholeHours);
				$(hoursfield).attr("readonly", "readonly");
				$(hoursfield + "span").attr("style", "display:none;");
				$(daysfield).val(0);
				$(daysfield + "span").html(0);
				$(daysfield).attr("readonly", "readonly");
				$(daysfield + "span").attr("style", "display:none;");
			}
		}

		/*
			获取三天前的日期
		*/
		function getBeforeDate() {
			var curDate = new Date(applicationDate);
			curDate.setDate(curDate.getDate() - 3);
			var curMonth = curDate.getMonth() + 1;
			if (curMonth < 10) {
				curMonth = "0" + curMonth;
			}
			var curDay = curDate.getDate();
			if (curDay < 10) {
				curDay = "0" + curDay;
			}
			var minDate = curDate.getFullYear() + '-' + curMonth + '-' + curDay;
			var startDate = $(startDatefield).val();//起始日期
			if (startDate < minDate) {
				alert("申请已超过3天有效期");
				return false;
			}
			return true;
		};

		/*
			获取两天后的日期
		*/
		function getAfterDate(sTime) {
			var curDate = new Date(sTime);
			curDate.setDate(curDate.getDate() + 2);
			var curMonth = curDate.getMonth() + 1;
			if (curMonth < 10) {
				curMonth = "0" + curMonth;
			}
			var curDay = curDate.getDate();
			if (curDay < 10) {
				curDay = "0" + curDay;
			}
			var minDate = curDate.getFullYear() + '-' + curMonth + '-' + curDay;
			return minDate;
		};
	</script>

</head>

</html>