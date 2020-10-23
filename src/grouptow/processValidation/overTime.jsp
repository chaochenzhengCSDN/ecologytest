<%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>
<%@page import="weaver.general.Util"%>
<%@page import="weaver.conn.RecordSet"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>

<head>
    <script type="text/javascript">
    /* 测试环境 */
/*      var overtimeType_field = "#field153131_";     // 加班类型下拉框
        var workHour_field = "#field153129_" ;        // 加班时长input框
        var applicationDate_field = "#field153119_" ; // 加班日期
        var is_rest_field = "#field153132_";          // 是否调休选项框
        var total_duration_field = "#field153126";    // 时长总计（小时）
        var userid_field = "#field153122";            // 加班申请人id
        var startTime_field ="#field156017_";         // 开始时间
        var endTime_field ="#field156018_";           // 结束时间*/
    /*  正式环境 */
        var overtimeType_field = "#field216566_";     // 加班类型下拉框
        var workHour_field = "#field216564_" ;        // 加班时长input框
        var applicationDate_field = "#field216561_" ; // 加班日期
        var is_rest_field = "#field216567_";          // 是否调休选项框
        var total_duration_field = "#field216560";    // 时长总计（小时）
        var userid_field = "#field216556";            // 加班申请人id
        var startTime_field ="#field216685_";         // 开始时间
        var endTime_field ="#field216686_";           // 结束时间
        jQuery(document).ready(function () {
            setEvent(0);
            $(workHour_field + "0").attr("readOnly", "readOnly");
            //流程提交前
            checkCustomize = function () {
                var bool = true;
                var _rowindex;
                $("input[name='check_node_0']").each(
                    function () {
                        _rowindex = $(this).val();
                        //检测提交日期是否在次月10日之前
                        //申请加班日期
                        var applicationDate = $(applicationDate_field + _rowindex).val();
                        var arr = applicationDate.split("-");
                        var year = arr[0];
                        var month = Number(arr[1]) + 1;
                        if (month < 10) {
                            month = "0" + month;
                        } else if (Number(month) == 12) {
                            month = "01";
                            year = Number(year) + 1;
                        }
                        var applicationDate1 = year + "-" + month + "-" + 10;
                        var date = new Date();
                        var month1 = date.getMonth() + 1;
                        if (month1 < 10) {
                            month1 = "0" + month1;
                        }
                        var day = date.getDate();
                        if (day < 10) {
                            day = "0" + day;
                        }
                        var minDate = date.getFullYear() + '-' + month1 + '-' + day;
                        if (applicationDate == "") {
                            bool =false;
                            return bool;
                        }
                        if (bool && applicationDate1 < minDate) {
                            window.top.Dialog.alert("您已超出流程申请时间！");
                            bool =false;
                            return bool;
                        }
                        //加班类型
                        var overtimeType = $(overtimeType_field + _rowindex).val();
                        //加班申请人id
                        var userid = $(userid_field).val();
                        //判断是否重复提交申请
                        if (bool) {
                            jQuery.ajax({
                                type: "POST",
                                cache: false,
                                async: false,
                                url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=isRepeat&overtimeType=" + overtimeType + "&dateTime=" + applicationDate + "&userid=" + userid,
                                success: function (str) {
                                    var json = eval('(' + str + ')');
                                    if (bool && json.count == 1) {
                                        window.top.Dialog.alert("申请存在重复日期(" + applicationDate + ")重复");
                                        bool =false;
                                        return bool;
                                    }
                                }
                            });
                        }
                        var wholeHours = $(total_duration_field).val();
                        if (wholeHours == 0) {
                            window.top.Dialog.alert("加班时长需大于0");
                            bool =false;
                            return bool;
                        }
                    })
                return bool;
            }
        });
    jQuery("button[name='addbutton0']").click(function () {//明细表添加一行，给明细表字段添加事件
        var rowindex = jQuery("input[name='check_node_0']").last().val();
        setEvent(rowindex);
        var rowindex = jQuery("input[name='check_node_0']").last().attr("_rowindex");
        setEvent(rowindex);
        $(workHour_field + rowindex).attr("readOnly", "readOnly");
    });
    jQuery("button[name='delbutton0']").click(function () {//明细表添加一行，给明细表字段添加事件
        var rowindex = jQuery("input[name='check_node_0']").last().val();
        wholeHoursChange();
        $(workHour_field + rowindex).attr("readOnly", "readOnly");
    });
    /**  overtimeType 加班类型
          *  0 正常工作日
          *  1 非工作日及法定假日
          *  2 晨会
          *  3 出差
        **/
        function setEvent(rowindex) {
            jQuery(overtimeType_field + rowindex).bindPropertyChange(function (obj) {
                var overtimeType = $(overtimeType_field + rowindex).val();//获取加班类型下拉框的value值
                var applicationDate = $(applicationDate_field + rowindex).val();//加班日期
                var personType = getSalaryType();//薪资方式
                var bool = true;
                // console.log("当前人员加班类型为:" + overtimeType);
                // console.log("当前人员为:" + personType);
                //0固薪 1时薪
                if(overtimeType !=""){
                    if (overtimeType == 0 && personType == 0) {
                        window.top.Dialog.alert("固薪人员无法申请正常日");
                        $(is_rest_field + rowindex).attr("style", "display:block;");
                        cleanAll(rowindex,1,2);
                        bool =false;
                        return bool;
                    } else if (overtimeType == 0 && personType == 1) {
                        $(is_rest_field + rowindex).val(1); //是否调休选项框
                        cleanAll(rowindex,0,2);
                    } else if(overtimeType == 2 && personType == 0){
                        window.top.Dialog.alert("固薪人员无法申请晨会");
                        $(is_rest_field + rowindex+"_readonlytext").html("");
                        $(is_rest_field + rowindex).attr("style", "display:none;");
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                        cleanAll(rowindex,1,2);
                        bool =false;
                        return bool;
                    } else if(overtimeType == 2 && personType == 1){
                        $(is_rest_field + rowindex+"_readonlytext").html("");
                        $(is_rest_field + rowindex).attr("style", "display:none;");
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                        cleanAll(rowindex,0,2);
                    } else if(overtimeType == 3){
                        $(is_rest_field + rowindex).attr("style", "display:block;");
                        cleanAll(rowindex,0,2);
                    }else{
                        cleanAll(rowindex,0,2);
                    }
                }
                if(overtimeType !=""&&applicationDate !=""){
                    checkOverType(rowindex);//检查加班类型与日期是否匹配
                }
            });
            //是否调休
            jQuery(is_rest_field + rowindex).bindPropertyChange(function (obj) {
                //获取加班类型下拉框的value值
                var overtimeType = $(overtimeType_field + rowindex).val();//加班类型
                var isBreakOff = $(is_rest_field + rowindex).val();//是否调休
                var applicationDate = $(applicationDate_field + rowindex).val();//加班日期
                var personType = getSalaryType();//薪资方式
                var week;//周几
                var attendancestatus; //是否是工作日
                var bool = true;
                jQuery.ajax({
                    type: "POST",
                    cache: false,
                    async: false,
                    data: { "workDate": applicationDate },
                    url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=getWeekAndAttendance&workDate=" + applicationDate,
                    success: function (str) {
                        var json = eval("(" + str + ")");
                        week = parseInt(json.week);
                        attendancestatus = parseInt(json.attendancestatus);
                    }
                });
                if(isBreakOff !=""){
                    if (overtimeType == 0 && isBreakOff == 0) {
                        window.top.Dialog.alert("正常工作日加班不允许调休");
                        $(is_rest_field + rowindex).val(1);
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                        bool =false;
                        return bool;
                    }
                     if (overtimeType == 1 && isBreakOff == 1 && personType == 0) {
                        window.top.Dialog.alert("固薪人员只能申请非正常工作日调休");
                        $(is_rest_field + rowindex).val(0);
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                         bool =false;
                         return bool;
                    }
                    if(($(is_rest_field + rowindex).val()==0)&&applicationDate !=""&&overtimeType==3&&attendancestatus==0){
                        window.top.Dialog.alert("正常工作日出差不能申请调休");
                        $(is_rest_field + rowindex).val(1);
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                        bool =false;
                        return bool;
                    }
                }
            });
            //在申请日期绑定事件 检验时间的有效性
            jQuery(applicationDate_field + rowindex).bindPropertyChange(function (obj) {
                var overtimeType = $(overtimeType_field + rowindex).val();//获取加班类型下拉框的value值
                var applicationDate = $(applicationDate_field + rowindex).val();//加班日期
                dateWithTypeCheck(overtimeType,applicationDate,rowindex); //日期类型重复性校验
                getSignTime(rowindex);
                if(overtimeType !=""&&applicationDate !=""){
                    checkOverType(rowindex);//检查加班类型与日期是否匹配
                }
            });

            //在开始时间绑定事件 检验时间的有效性
            jQuery(startTime_field + rowindex).bindPropertyChange(function (obj) {
                getSignTime(rowindex);
            });
            //在结束时间绑定事件 检验时间的有效性
            jQuery(endTime_field + rowindex).bindPropertyChange(function (obj) {
                getSignTime(rowindex);
            });
            //时间改变事件 加班时长input框
            jQuery(workHour_field + rowindex).bindPropertyChange(function (obj) {
                var thisid = jQuery(obj).attr("id");
                _rowindex = thisid.substring(thisid.indexOf("_") + 1);
                var workHour;
                var wholeHours = 0;
                $("input[name='check_node_0']").each(
                    function () {
                        _rowindex = $(this).val();
                        workHour = $(workHour_field + _rowindex).val();
                        wholeHours = Number(workHour) + Number(wholeHours);
                    }
                )
                $(total_duration_field).val(Math.round(wholeHours * 100) / 100);
            })
        }

        //获取打卡时间并校验
        function getSignTime(rowindex) {
            var startTime=$(startTime_field+rowindex).val();//开始时间
            var endTime=$(endTime_field+rowindex).val();//结束时间
            if(startTime !=""&&endTime !=""){
                compareWorkTime(rowindex);
            }
        };
        //对开始时间和结束时间进行校验
        function compareWorkTime(rowindex) {
            var startTime=$(startTime_field+rowindex).val();//开始时间
            var endTime=$(endTime_field+rowindex).val();//结束时间
            var startTimeForMin=parseInt(startTime.split(":")[0])*60+parseInt(startTime.split(":")[1]);//开始时间对应的分钟数
            var endTimeForMin=parseInt(endTime.split(":")[0])*60+parseInt(endTime.split(":")[1]);//结束时间对应的分钟数
            var userid = $(userid_field).val();//申请人
            var applicationDate = $(applicationDate_field + rowindex).val();//加班日期
            var overtimeType = $(overtimeType_field + rowindex).val();//加班类型
            var res1;
            var week;//周几
            var attendancestatus; //是否是工作日
            var workHour;
            var businesstripStartTime;
            var businesstripendTime;
            var bool = true;
            jQuery.ajax({
                type: "POST",
                cache: false,
                async: false,
                url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=getTypeTime&userid=" + userid + "&applicationDate=" + applicationDate,
                success: function (str) {
                    var json = eval("(" + str + ")");
                    var res = json.list;
                    res1 = res.substring(res.indexOf('[') + 1, res.indexOf(']'));
                }
            });
            jQuery.ajax({
                type: "POST",
                cache: false,
                async: false,
                data: { "workDate": applicationDate },
                url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=getWeekAndAttendance&workDate=" + applicationDate,
                success: function (str) {
                    var json = eval("(" + str + ")");
                    week = parseInt(json.week);
                    attendancestatus = parseInt(json.attendancestatus);
                }
            });

            jQuery.ajax({
                type: "POST",
                cache: false,
                async: false,
                url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=calculateTheBusinessTripTime&userid=" + userid + "&applicationDate=" + applicationDate,
                success: function (str) {
                    var json = eval("(" + str + ")");
                    businesstripStartTime=json.startTime;
                    businesstripendTime=json.endTime;
                }
            });

            if(overtimeType==0){
                //开始时间校验
                var standOutTimeForMin=1035;//17：15对应的分钟数
                if(overtimeType==0&&startTimeForMin<standOutTimeForMin){
                    window.top.Dialog.alert("正常工作日加班开始时间不能小于17：15");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                var signOutTime;
                if(res1==""){
                    window.top.Dialog.alert("当天无打卡记录，无法在该时间段申请加班");
                    bool =false;
                    return bool;
                }
                //结束时间校验
                var lastIndex=parseInt(res1.split(",").length)-1;
                signOutTime=res1.split(",")[lastIndex].trim().substring(0,5);
                var signOutTimeForMin=parseInt(signOutTime.split(":")[0].trim()) * 60 + parseInt(signOutTime.split(":")[1].trim());
                if(endTimeForMin>signOutTimeForMin&&signOutTime!=""){
                    window.top.Dialog.alert("正常工作日加班结束时间不能大于"+signOutTime.trim().substring(0,5));
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                if(startTime>endTime){
                    window.top.Dialog.alert("正常工作日开始时间不能大于结束时间");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                if (workHour < 0.5) {
                    workHour = 0;
                }else if(workHour>3){
                    workHour = 3;
                }
            }else if(overtimeType==1){
                if(res1==""){
                    window.top.Dialog.alert("当天无打卡记录，无法在该时间段申请加班");
                    bool =false;
                    return bool;
                }
                if (attendancestatus == 2) {
                    var signOutTime;
                    var index;
                    for (var i = 0; i < res1.split(",").length - 1; i++) {
                        signOutTime = res1.split(",")[i];
                        if (signOutTime.endsWith("1") && parseInt(signOutTime.split(":")[0].trim()) >= 12) {
                            index = i;
                            //console.log(index);
                            break;
                        }
                    }
                    var signOutTimeForMin = parseInt(res1.split(",")[index].split(":")[0].trim()) * 60 + parseInt(res1.split(",")[index].split(":")[1].trim());
                    if (signOutTimeForMin > startTimeForMin) {
                        window.top.Dialog.alert("非正常工作日开始时间不能小于" + res1.split(",")[index].trim().substring(0, 5));
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }
                    signOutTimeForMin = parseInt(res1.split(",")[res1.split(",").length - 1].split(":")[0].trim()) * 60 + parseInt(res1.split(",")[res1.split(",").length - 1].split(":")[1].trim());
                    if (signOutTimeForMin < endTimeForMin) {
                        window.top.Dialog.alert("非正常工作日结束时间不能大于" + res1.split(",")[res1.split(",").length - 1].trim().substring(0, 5));
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }
                    if (startTime > endTime) {
                        window.top.Dialog.alert("正常工作日开始时间不能大于结束时间");
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }
                    //开始时间和结束时间校验
                    //console.log("当天打卡数据:"+res1);
                    startTimeForMin=startTimeForMin<=780?780:startTimeForMin;//开始时间去除中午的时间
                    workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    if (workHour >= 5.75) {
                        workHour = 5.75;
                    } else if (workHour < 0.5) {
                        workHour = 0;
                    }
                } else {
                    var signOutTime;
                    var index;
                    for (var i = 0; i < res1.split(",").length - 1; i++) {
                        signOutTime = res1.split(",")[i];
                        if (signOutTime.endsWith("1")) {
                            index = i;
                            //console.log(index);
                            break;
                        }
                    }
                    var signOutTimeForMin = parseInt(res1.split(",")[index].split(":")[0].trim()) * 60 + parseInt(res1.split(",")[index].split(":")[1].trim());
                    if (signOutTimeForMin > startTimeForMin) {
                        window.top.Dialog.alert("非正常工作日开始时间不能小于" + res1.split(",")[index].trim().substring(0, 5));
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }
                    signOutTimeForMin = parseInt(res1.split(",")[res1.split(",").length - 1].split(":")[0].trim()) * 60 + parseInt(res1.split(",")[res1.split(",").length - 1].split(":")[1].trim());
                    if (signOutTimeForMin < endTimeForMin) {
                        window.top.Dialog.alert("非正常工作日结束时间不能大于" + res1.split(",")[res1.split(",").length - 1].trim().substring(0, 5));
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }
                    if (startTime > endTime) {
                        window.top.Dialog.alert("正常工作日开始时间不能大于结束时间");
                        cleanAll(rowindex,0,0);
                        bool =false;
                        return bool;
                    }

                    if(startTimeForMin<11*60+45&&endTimeForMin<11*60+45){
                        workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    }else if(startTimeForMin<11*60+45&&endTimeForMin>=11*60+45&&endTimeForMin<13*60){
                        endTimeForMin=11*60+45;
                        workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    }else if(startTimeForMin<11*60+45&&endTimeForMin>=13*60){
                        startTimeForMin=startTimeForMin+75;//开始时间去除中午的时间
                        workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    }else if(startTimeForMin>=11*60+45&&startTimeForMin<13*60&&endTimeForMin>=11*60+45&&endTimeForMin<13*60){
                        workHour =0;
                    }else if(startTimeForMin>=11*60+45&&startTimeForMin<13*60&&endTimeForMin>=13*60){
                        startTimeForMin=780;//开始时间去除中午的时间
                        workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    }else if(startTimeForMin>=13*60&&endTimeForMin>=13*60){
                        workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                    }
                    if (workHour >= 9) {
                        workHour = 9;
                    } else if (workHour < 0.5) {
                        workHour = 0;
                    }
                }
            }else if(overtimeType==2){
                if(res1==""){
                    window.top.Dialog.alert("当天无打卡记录，无法在该时间段申请加班");
                    bool =false;
                    return bool;
                }
                var signOutTime=res1.split(",")[0];//打卡开始时间
                var signOutTimeForMin=parseInt(signOutTime.split(":")[0].trim())*60+parseInt(signOutTime.split(":")[1].trim());//打卡开始时间对应的分钟数
                var standInTime=510;
                if(signOutTime==""){
                    window.top.Dialog.alert("晨会当天无签到时间");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                if(signOutTimeForMin>startTimeForMin){
                    window.top.Dialog.alert("晨会开始时间不能小于"+signOutTime.substring(0,5));
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                if(standInTime<endTimeForMin){
                    window.top.Dialog.alert("晨会结束时间不能大于08：30");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                if(startTime>endTime){
                    window.top.Dialog.alert("晨会开始时间不能大于结束时间");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                if (workHour < 0.5) {
                    workHour = 0;
                }else{
                    workHour =0.5;
                }
            }else if(overtimeType==3){
                if(businesstripStartTime==""||businesstripendTime==""){
                    window.top.Dialog.alert("当天无出差申请或者无业务考勤");
                    bool =false;
                    return bool;
                }
                var businesstripStartTimeMin=parseInt(businesstripStartTime.split(":")[0].trim())*60+parseInt(businesstripStartTime.split(":")[1].trim());
                var businesstripendTimeMin=parseInt(businesstripendTime.split(":")[0].trim())*60+parseInt(businesstripendTime.split(":")[1].trim());
                if(startTime>endTime){
                    window.top.Dialog.alert("加班开始时间不能大于结束时间");
                    cleanAll(rowindex,0,0);
                    bool =false;
                    return bool;
                }
                //正常工作日出差
                if(attendancestatus==0){
                    if(($(is_rest_field + rowindex).val()==0)&&applicationDate !=""){
                        window.top.Dialog.alert("正常工作日出差不能申请调休");
                        $(is_rest_field + rowindex).val(1);
                        $(is_rest_field + rowindex + "span").attr("style", "display:none;");
                        bool =false;
                        return bool;
                    }
                    if((businesstripStartTime==""||businesstripendTime=="")){
                        window.top.Dialog.alert("正常工作日出差当天无出差申请或无业务考勤记录");
                        cleanAll(rowindex,0,0);
                    }else{
                        if(startTimeForMin<17*60+15){
                            window.top.Dialog.alert("正常工作日出差开始时间不能小于17：15");
                            cleanAll(rowindex,0,0);
                        }else{
                            workHour = Math.round((endTimeForMin - (17*60+15)) / 60 * 100) / 100;
                            if (workHour < 0.5) {
                                workHour = 0;
                            }else if(workHour>=1){
                                workHour = 1;
                            }
                        }
                    }
                }
                //周六半日出差
                if(attendancestatus==2){
                    if((businesstripStartTime==""||businesstripendTime=="")){
                        window.top.Dialog.alert("周六当天无出差申请或无业务考勤记录");
                        cleanAll(rowindex,0,0);
                    }else{
                        if(startTimeForMin<12*60){
                            window.top.Dialog.alert("周六当天出差开始时间不能小于12：00");
                            cleanAll(rowindex,0,0);
                        }else{
                            if(businesstripStartTimeMin>startTimeForMin){
                                window.top.Dialog.alert("出差开始时间不能小于"+businesstripStartTime.trim().substring(0,5));
                                cleanAll(rowindex,0,0);
                                bool =false;
                                return bool;
                            }
                            if(businesstripendTimeMin<endTimeForMin){
                                window.top.Dialog.alert("出差结束时间不能大于"+businesstripendTime.trim().substring(0,5));
                                cleanAll(rowindex,0,0);
                                bool =false;
                                return bool;
                            }
                            startTimeForMin=startTimeForMin<=780?780:startTimeForMin;
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                            if (workHour < 0.5) {
                                workHour = 0;
                            }else if(workHour>=5.75){
                                workHour =5.75;
                            }
                        }
                    }
                }
                //非工作日出差
                if(attendancestatus==1){
                    if((businesstripStartTime==""||businesstripendTime=="")){
                        window.top.Dialog.alert("周末当天无出差申请或无业务考勤记录");
                        cleanAll(rowindex,0,0);
                    }else{
                        if(businesstripStartTimeMin>startTimeForMin){
                            window.top.Dialog.alert("出差开始时间不能小于"+businesstripStartTime.trim().substring(0,5));
                            cleanAll(rowindex,0,0);
                            bool =false;
                            return bool;
                        }
                        if(businesstripendTimeMin<endTimeForMin){
                            window.top.Dialog.alert("出差结束时间不能大于"+businesstripendTime.trim().substring(0,5));
                            cleanAll(rowindex,0,0);
                            bool =false;
                            return bool;
                        }
                        if(startTimeForMin<11*60+45&&endTimeForMin<11*60+45){
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                        }else if(startTimeForMin<11*60+45&&endTimeForMin>=11*60+45&&endTimeForMin<13*60){
                            endTimeForMin=11*60+45;
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                        }else if(startTimeForMin<11*60+45&&endTimeForMin>=13*60){
                            startTimeForMin=startTimeForMin+75;//开始时间去除中午的时间
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                        }else if(startTimeForMin>=11*60+45&&startTimeForMin<13*60&&endTimeForMin>=11*60+45&&endTimeForMin<13*60){
                            workHour =0;
                        }else if(startTimeForMin>=11*60+45&&startTimeForMin<13*60&&endTimeForMin>=13*60){
                            startTimeForMin=780;//开始时间去除中午的时间
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                        }else if(startTimeForMin>=13*60&&endTimeForMin>=13*60){
                            workHour = Math.round((endTimeForMin - startTimeForMin) / 60 * 100) / 100;
                        }
                        if (workHour < 0.5) {
                            workHour = 0;
                        }else if(workHour>=9){
                            workHour = 9;
                        }
                    }
                }
            }
            $(workHour_field + rowindex).val(workHour);
            $(workHour_field + rowindex+"span").attr("style","display:none");
        }

    /**
     * 查看当前申请人员的薪资方式
     */
    function getSalaryType(){
        var userid = $(userid_field).val(); //申请人
        var salaryType;
        jQuery.ajax({
            type: "POST",
            cache: false,
            async: false,
            url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=getSalaryType&userid=" + userid ,
            success: function (str) {
                var json = eval("(" + str + ")");
                salaryType=json.salaryType;
                //console.log("薪资方式为:"+salaryType);
            }
        });
        return salaryType;
    }
    /**
     * 检查加班类型与日期是否匹配
     */
    function checkOverType(rowindex){
        var applicationDate = $(applicationDate_field + rowindex).val();//加班日期
        var overtimeType = $(overtimeType_field + rowindex).val();//加班类型
        var attendancestatus;
        var week;
        var bool = true;
        jQuery.ajax({
            type: "POST",
            cache: false,
            async: false,
            data: { "workDate": applicationDate },
            url: "/iiot/grouptow/processValidation/overTime_ajax.jsp?action=getWeekAndAttendance&workDate=" + applicationDate,
            success: function (str) {
                var json = eval("(" + str + ")");
                week = parseInt(json.week);
                attendancestatus = parseInt(json.attendancestatus);
            }
        });
        if(overtimeType==1&&attendancestatus == 0){
            window.top.Dialog.alert("当天为工作日，无法申请非工作日加班");
            $(applicationDate_field + rowindex).val("");
            $(applicationDate_field+rowindex+"span").html("");
            bool =false;
            return bool;
        }else if(overtimeType==0&&(attendancestatus ==1 || attendancestatus == 2)){
            window.top.Dialog.alert("当天为非工作日，无法申请工作日加班");
            $(applicationDate_field + rowindex).val("");
            $(applicationDate_field+rowindex+"span").html("");
            bool =false;
            return bool;
        }
    }
    /**
     * 清除所有值
     */
    function cleanAll(rowindex,numa,numb) {
        //实际值
        $(is_rest_field + rowindex).val("");
        if (numa == 1) {//加班类型判断
            $(overtimeType_field + rowindex).val("");
        }
        if (numb == 2) {//日期判断
            $(applicationDate_field + rowindex).val("");
        }
        $(startTime_field + rowindex).val("");
        $(endTime_field + rowindex).val("");
        $(workHour_field + rowindex).val("");
        //折叠显示
        $(is_rest_field + rowindex+"span").html("");
        if ( numa == 1) {//加班类型判断
            $(overtimeType_field + rowindex + "span").html("");
        }
        if ( numb == 2){//日期判断
            $(applicationDate_field + rowindex + "span").html("");
        }
        $(startTime_field + rowindex+"span").html("");
        $(endTime_field + rowindex+"span").html("");
        $(workHour_field + rowindex+"span").html("");
    }
    /**
     * 时间改变事件
     */
    function wholeHoursChange() {
        var workHour;
        var wholeHours = 0;
        $("input[name='check_node_0']").each(
            function () {
                var rowindex = $(this).val();
                    workHour = $(workHour_field + rowindex).val();
                  wholeHours = Number(workHour) + Number(wholeHours);
            }
        );
        $(total_duration_field).val(Math.round(wholeHours * 100) / 100);
    }
    /**
     * 日期类型重复性校验
     */
    function dateWithTypeCheck(overtimeType, applicationDate,index) {
        var rowindex = jQuery("input[name='check_node_0']").last().val();
        for (var i = 0; i <= rowindex; i++) {
            if ((applicationDate == $(applicationDate_field + i).val()) && (overtimeType == $(overtimeType_field + i).val()) && i != index) {
                window.top.Dialog.alert("该记录已存在");
                cleanAll(index,0,2);
                break;
            }
        }
    }
    </script>
</head>

</html>