<?php
if (file_exists('../config.php')) {
    require_once('../config.php');
} 
elseif (file_exists('config.php')) {
    require_once('config.php');
}
require(__DIR__ . '/utils/string.php');

function getPaginationSnippets($os, $isDomesticQA)
{
    $pageContents = "";

    if ($isDomesticQA) { // QA 전용 페이지
        $fileKey = "html*";
    } else {
        $fileKey = "html";
    }

    if ($os == "android") {
        $files = glob("../android_distributions/[0-9].*/*.$fileKey");
    }
    else if ($os == "ios") {
        $files = glob("../ios_distributions/[0-9].*/*.$fileKey");
    }

    usort($files, function($a, $b) {
        return filemtime($a) < filemtime($b);
    });

    $CardsPerSite = 20;
    $total_data = count($files);
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;     // GETTING PAGE NUMBER FROM URL

    if (empty($page) || $page == 1) {
        $start_val = 0;
        $end_val = $CardsPerSite - 1;
    } else {
        $start_val = ($page * $CardsPerSite) - $CardsPerSite;
        $end_val = $start_val + ($CardsPerSite - 1);
    }

    // for($i=$start_val;$i<=$end_val;$i++){
    //     echo $files[$i].' ';
    // }

    $less_than = $total_data / $CardsPerSite;
    if ($less_than > intval($less_than)) $less_than = $less_than + 1;

    if ($total_data > 1) {
        $pageContents .= '<div class="pagination">';
        $pageContents .= ($page - 1) > 0 ? '<a href="?page=' . ($page - 1) . '">'. L::page_prev .'</a><span class="bar">|</span>' : L::page_prev .'<span class="bar">|</span>';
        for ($i = 1; $i <= $less_than; $i++) {
            if ($page == $i) $pageContents .= '<a class="on">';
            else $pageContents .= '<a href="?page=' . $i . '">';
            $pageContents .= $i;
            $pageContents .= '</a><span class="bar">|</span>';
        }
        $pageContents .= ($page + 1) <= $less_than ? '<a href="?page=' . ($page + 1) . '">'. L::page_next .'</a>' : L::page_next;
        $pageContents .= '</div>';
        $pageContents .= '<BR />';
    }

    $result = array();
    array_push($result, array_slice($files, $start_val, $end_val));
    array_push($result, $pageContents);
    array_push($result, $page . "/" . (int)$less_than);

    return $result;
}

function getHtmlSnippets($os, $isDomesticQA, $isSearch, $searchPattern, $files): string
{
    global $json;
    global $config;
    global $frontEndProtocol;
    global $frontEndPoint;
    global $outBoundProtocol;
    global $outBoundPoint;
    global $topPath;
    global $isDebugMode;

    $finalContents = "";

    foreach($files as $file) {
        $content = file_get_contents($file);

        $typeKey = "2"; // default: box_type2(배포후)
        if ($isDomesticQA) {
            // QA 전용 페이지 ///////////////////////////////////////////////////////////
            if (endsWith($file, "html.bak")) {
                continue;
            } else if (endsWith($file, "html.deleted")) {
                // for 회사 내부 QA 페이지용만 bak에 대해서 처리함 on 2019.11.22
                $path = pathinfo($file, PATHINFO_DIRNAME);
                $filename = basename($file, '.deleted');
                if (file_exists("$path/$filename")) {
                    // TODO: 원본을 지워야할까? 아님 .deleted를 지워야할깡? on 2019.11.24
                    //continue;
                }
                //$content = preg_replace("/(<div class=\"large-4 columns\">)(<a href=\"\.\.\/remove_html_snippet\.php)(.*)(\">.*a>)/", "$1<!-- $2$3$4 --><br /><span style=\"position: relative;margin-top: -10px;margin-right: 10px;right: 0px;float: right;\">[<font color=red><b>삭제됨</b></font>]&nbsp;<a href='../undo_remove_html_snippet.php$3'>UNDO</a></span>", $content);
                // <!-- 5타입 : box_type1(배포전), box_type2(배포후), box_type3(입고 검증전), box_type4(입고 검증후), box_type_del(삭제) -->
                $typeKey = "_del";
                //$content = preg_replace("/(<div class=\"item box_type)*(\">*$)/", "$1". $typeKey ."$2", $content);
            } else if (startsWith(basename($file), "zzz_")) {
                // 아직 배포되지 않은 페이지
                // DONE: 배포 목적 및 수정 사항 등 기재할 수 있도록 해야함 by EungShik Kim on 2019.11.24
                //$content = preg_replace("/(<!--DIST_BOTTON--><a href=\")*(\" class=\"btn_share\"><span class=\"hide\">공유</span></a>)/", "$1../distributions.php?os=ios&file=$file$2", $content);

                // <!-- 5타입 : box_type1(배포전), box_type2(배포후), box_type3(입고 검증전), box_type4(입고 검증후), box_type_del(삭제) -->
                $typeKey = "1";
                //$content = preg_replace("/(<div class=\"item box_type)*(\">*$)/", "$1". $typeKey ."$2", $content);
            }
        } else {
            // 외부(고객사) 배포 페이지 //////////////////////////////////////////////////////////
            if (startsWith(basename($file), "zzz_")) {
                // 아직 배포되지 않은 페이지
                continue;
            }
        }

        if ($typeKey != "_del") {
            if ($os == "android" && strpos($content, '(스토어 배포용)')) {
                // <!-- 5타입 : box_type1(배포전), box_type2(배포후), box_type3(입고 검증전), box_type4(입고 검증후), box_type_del(삭제) -->
                if (startsWith(basename($file), "zzz_")) {
                    $typeKey = "3";
                } else {
                    $typeKey = "4";
                }
                //$content = preg_replace("/(<div class=\"item box_type)*(\">*$)/", "$1". $typeKey ."$2", $content);
            } else if ($os == "ios" && strpos($content, '(앱스토어 검증버전)')) {
                // <!-- 5타입 : box_type1(배포전), box_type2(배포후), box_type3(입고 검증전), box_type4(입고 검증후), box_type_del(삭제) -->
                if (startsWith(basename($file), "zzz_")) {
                    $typeKey = "3";
                } else {
                    $typeKey = "4";
                }
                //$content = preg_replace("/(<div class=\"item box_type)*(\">*$)/", "$1". $typeKey ."$2", $content);
            }
        }


        // START: '배포목적' TAG박스 표시
        $versionTarget = "";
        $versionDetail = "";
        $path = pathinfo($file, PATHINFO_DIRNAME);
        $basename = basename($file);
        if (endsWith($file, "deleted")) {
            $basenameWithoutExt = basename($file, '.html.deleted');
        } else {
            $basenameWithoutExt = basename($file, '.html');
        }
        $incFilename = $basenameWithoutExt . ".inc.php";
        if (file_exists("$path/$incFilename")) { // 배포 후
            require_once("$path/$incFilename");
            if (isset($version_target) && strlen($version_target) > 0) {
                $altText = "";
                if (isset($version_details) && strlen($version_details) > 0) {
                    $altText = "(" . $version_details . ")";
                }
                $content = preg_replace("/(<h2 class=\"tit_box\"><span class=\"txt\">)*(<\/span><\/h2>)/", "$1$version_target$altText$2", $content);
                $versionTarget = $version_target;
                $versionDetail = $altText;
                unset($version_target);
                unset($version_details);
            }
        }
        if ($typeKey == "_del") {
            // 삭제됨
            $versionTarget = strlen($versionTarget) > 0 ? "<s>$versionTarget</s>&gt;&nbsp;삭제됨" : "삭제됨";
        } else if ($typeKey == "4" && strlen($versionTarget) == 0) {
            // 검증 입고 완료 버전
            $versionTarget = L::title_tab_qc_version;
        }
        // E N D: '배포목적' TAG박스 표시


        // START: Fetch JSON data
        if (startsWith($basenameWithoutExt, "zzz_")) {
            // $tmpOut = explode("zzz_", $basenameWithoutExt);
            // $basenameWithoutExt = $tmpOut[1];
            $basenameWithoutExt = substr($basenameWithoutExt, 4);

            //echo "<H1><font color=pink>JSON FILE:::$basenameWithoutExt</font></H1>";
        }
        $jsonfile = $basenameWithoutExt . ".json";
        $finalSnippet = "";
        if (file_exists("$path/$jsonfile")) {
            $jsonStr = file_get_contents("$path/$jsonfile");
            $finalJson = json_validate($jsonStr);

            if ($os == "ios") {
                $osName = L::os_ios;
            } else {
                $osName = L::os_android;
            }
            if ($typeKey != "_del") {
                if ($finalJson->{'releaseType'} == 'release') {
                    if (startsWith(basename($file), "zzz_")) {
                        $typeKey = "3";
                    } else {
                        $typeKey = "4";
                    }
                } elseif ($os == "ios") {
                    $appstoreIPA = glob("../ios_distributions/[1-9].*/" . $basenameWithoutExt . "_AppStore.ipa");
                    if (count($appstoreIPA) > 0) {
                        if (startsWith(basename($file), "zzz_")) {
                            $typeKey = "3";
                        } else {
                            $typeKey = "4";
                        }
                    }
                }
            }

            $distMode=$finalJson->{'releaseType'};

            // Removal script from original html snippet
            if (strpos($content, "remove_html_snippet")) {
                $tempStr = explode("remove_html_snippet", $content);
                $prefixStr = explode("\"><img", $tempStr[1]);
                $removalUrl = "../remove_html_snippet" . $prefixStr[0];

                $undoRemovalUrl = preg_replace("/remove_html_snippet/", "undo_remove_html_snippet", $removalUrl);
            }
            // Above is legacy, now we can pass filename as arguments, 2021.08.01
            if ($isDebugMode) {
                $removalUrl = "../remove_html_snippet.php?os=$os&file=" . urlencode($basenameWithoutExt);
                $undoRemovalUrl = "../undo_remove_html_snippet.php?os=$os&file=" . urlencode($basenameWithoutExt);
                // Share script from original html snippet
                $shareUrl = "../distributions.php?os=$os&type=$distMode&file=$file";
            } else {
                // It's not plf'2'mini.company.com domain
                $inBoundPoint = "$frontEndProtocol://$frontEndPoint/$topPath";
                $removalUrl = "$inBoundPoint/remove_html_snippet.php?os=$os&file=" . urlencode($basenameWithoutExt);
                $undoRemovalUrl = "$inBoundPoint/undo_remove_html_snippet.php?os=$os&file=" . urlencode($basenameWithoutExt);
                // Share script from original html snippet
                $shareUrl = "$inBoundPoint/distributions.php?os=$os&type=$distMode&file=" . urlencode($file);
            }
            $resendingUrl = $shareUrl . "&resending=true";

            // START: Make HTML Snippet with JSON data
            $finalSnippet = "
<!-- " . $finalJson->{'appVersion'} . "." . $finalJson->{'buildVersion'} . " jenkins(" . $finalJson->{'buildNumber'} . ") START -->
<div class=\"item box_type$typeKey\"> <!-- 5타입 : box_type1(배포전), box_type2(배포후), box_type3(입고 검증전), box_type4(입고 검증후), box_type_del(삭제) -->
<div class=\"item_inner\">
";
            $finalSnippet .= "
<h2 class=\"tit_box\"><span class=\"txt\">
";
            if ($isDomesticQA && $typeKey != "_del") {
                $finalSnippet .= "<a href=\"$resendingUrl\" alt=\"". L::title_alt_resend_mail ."\">";
            }
            $finalSnippet .= "$versionTarget";
            if (strlen(trim($versionDetail)) > 0) {
                $finalSnippet .= "<br /><font size=1>$versionDetail</font>";
            }
            if ($isDomesticQA && $typeKey != "_del") {
                $finalSnippet .= "</a>";
            }
            $finalSnippet .= "</span></h2>";
            $finalSnippet .= "<!--COPY_BOTTON --><a class=\"btn_copy\" onclick=\"copyToClip('[$versionTarget $versionDetail] ";
            $finalSnippet .= L::app_name ." $osName v" . $finalJson->{'appVersion'} . ".";
            $finalSnippet .= $finalJson->{'buildVersion'} . " (" . $finalJson->{'buildTime'} . "), Jenkins(";
            $finalSnippet .= $finalJson->{'buildNumber'} . ")')\"><span class=\"hide\">복사</span></a>
<!--DIST_BOTTON --><a href=\"$shareUrl\" class=\"btn_share\"><span class=\"hide\">공유</span></a>
<!--REMOVE_BOTTON--><a href=\"javascript:deleteFiles('$removalUrl');\" class=\"btn_del\"><span class=\"hide\">삭제</span></a><a href=\"$undoRemovalUrl\" class=\"btn_re\"><span class=\"hide\">되돌리기</span></a>
<div class=\"cont\">
<span class=\"date\">" . $finalJson->{'buildTime'} . "</span>
<p class=\"stit\"><strong class=\"point_c\">". L::app_name ." ". $osName;
            $finalSnippet .= "</strong> <span>v" . $finalJson->{'appVersion'} . "." . $finalJson->{'buildVersion'};
            $finalSnippet .= "&nbsp;&nbsp;&nbsp;<font size=1 color=silver>jenkins(<b>" . $finalJson->{'buildNumber'} . "</b>)</font></span></p>";

            if (is_array($finalJson->{'files'})) {
                $finalSnippet .= "<ul class=\"list_down\">";

                for ($i = 0; $i < count($finalJson->{'files'}); $i++) {

                    $anItem = $finalJson->{'files'}[$i];

                    if (rtrim($anItem->{'file'}) != "") {
                        $binTitle = $anItem->{'title'};
                        if (!$isDomesticQA) {
                            if ($os == "ios") {
                                if ($finalJson->{'releaseType'} == 'release') {
                                    if ($json->{$os}->{'AppStore'}->{'title'} == $binTitle) {
                                        if ($json->{$os}->{'AppStore'}->{'showToClient'} != true) continue;
                                    }
                                }
                                if ($json->{$os}->{'Adhoc'}->{'title'} == $binTitle) {
                                    if ($json->{$os}->{'Adhoc'}->{'showToClient'} != true) continue;
                                }
                                if ($json->{$os}->{'Enterprise'}->{'title'} == $binTitle) {
                                    if ($json->{$os}->{'Enterprise'}->{'showToClient'} != true) continue;
                                }
                            } else if ($os == "android") {
                                if ($finalJson->{'releaseType'} == 'release') {
                                    if ($json->{$os}->{'GoogleStore'}->{'title'} == $binTitle) {
                                        if ($json->{$os}->{'GoogleStore'}->{'showToClient'} != true) continue;
                                    }
                                    if ($json->{$os}->{'OneStore'}->{'title'} == $binTitle) {
                                        if ($json->{$os}->{'OneStore'}->{'showToClient'} != true) continue;
                                    }
                                }
                                if ($json->{$os}->{'LiveServer'}->{'title'} == $binTitle) {
                                    if ($json->{$os}->{'LiveServer'}->{'showToClient'} != true) continue;
                                }
                                if ($json->{$os}->{'TestServer'}->{'title'} == $binTitle) {
                                    if ($json->{$os}->{'TestServer'}->{'showToClient'} != true) continue;
                                }
                            }
                        }

                        $downUrl = $anItem->{'file'};

                        if (!startsWith($downUrl, "http") &&
                            strpos($downUrl, 'android_signing.php') === false) {
                            $downUrl = $finalJson->{'urlPrefix'} . $downUrl;
                        }

                        if (strlen(rtrim($anItem->{'plist'})) > 0) {
                            $plistUrl = rtrim($anItem->{'plist'});
                            if (!startsWith($plistUrl, "http")) {
                                $plistUrl = $finalJson->{'urlPrefix'} . $plistUrl;
                            }
                            $downUrl = "itms-services://?action=download-manifest&url=" . $plistUrl;
                        }

                        if (!$isDebugMode) {
                            // It's not plf'2'mini.company.com domain
                            $downUrl = str_replace($frontEndProtocol, $outBoundProtocol, $downUrl);
                            $downUrl = str_replace($frontEndPoint, $outBoundPoint, $downUrl);
                            $downUrl = str_replace("httpss", "https", $downUrl);
                            
                            $tempUrl = $downUrl;
                            if (isset($plistUrl)) {
                                $tempUrl = $plistUrl;
                            }
                            $tempHost = parse_url($tempUrl, PHP_URL_HOST);
                            $tempPort = parse_url($tempUrl, PHP_URL_PORT);
                            $exEndPoint = $tempHost;
                            if ($tempPort > 0) {
                                $exEndPoint .= ":" . $tempPort;
                            }
                            // if ($frontEndProtocol != $exEndPoint) {
                                $downUrl = str_replace($exEndPoint, $outBoundPoint, $downUrl);
                            // }
                        }

                        if (strpos($downUrl, 'android_signing.php') !== false) {
                            if (! $isDomesticQA) { 
                                continue;
                            }

                            $finalURL = str_replace($outBoundPoint, $frontEndPoint, $downUrl);
                            $array = explode('title=', $finalURL);
                            $apkFile = end($array);
                            $isGoogleExist = 0;
                            $isOneStoreExist = 0;

                            $unsignedPrefix = $json->{$os}->{'outputUnsignedPrefix'};
                            $googleSuffix = $json->{$os}->{'outputGoogleStoreSuffix'};
                            // if ($json->{$os}->{'GoogleStore'}->{'usingBundleAAB'}) {
                            //     $googleSuffix = str_replace('apk', 'aab', $googleSuffix);
                            // }
                            if (file_exists("$path/$unsignedPrefix$apkFile$googleSuffix")) {
                                $isGoogleExist = 1;
                            }
                            $oneSuffix = $json->{$os}->{'outputOneStoreSuffix'};
                            // if ($json->{$os}->{'OneStore'}->{'usingBundleAAB'}) {
                            //     $oneSuffix = str_replace('apk', 'aab', $googleSuffix);
                            // }
                            if (file_exists("$path/$unsignedPrefix$apkFile$oneSuffix")) {
                                $isOneStoreExist = 1;
                            }
                            $apkSignerPath = $json->{'android'}->{'androidHome'} . "/build-tools";
                            $apksignerCandidates = glob($apkSignerPath . "/*/apksigner");
                            $lastApkSigner = end($apksignerCandidates);
                            if (file_exists($lastApkSigner)) {
                                $anArray = explode('/', $lastApkSigner);
                                $apkSignerVersion = $anArray[count($anArray) - 2];
                                $finalURL = "javascript:androidSigning('$finalURL','$apkFile','$apkSignerVersion',$isGoogleExist,$isOneStoreExist);";
                            } else {
                                $apkSignerVersion = '0';
                                $finalURL = "javascript:androidSigning('$apkSignerPath','$apkFile','$apkSignerVersion',$isGoogleExist,$isOneStoreExist);";
                            }
                        } else {
                            $finalURL = "javascript:appDownloader('$downUrl');";
                            if (startsWith(ltrim($anItem->{'title'}), "Enterprise4Web")) {
                                $finalURL = "javascript:enterprise4web('$downUrl');";
                            }
                        }

                        $itemClassForAppStore = "";
                        $itemClassForAppStoreDesc = "";
                        $appStoreUploadLink = "";
                        // iOS Upload to App Store
                        if ($os == "ios" && $finalJson->{'releaseType'} == 'release' && 
                            $json->{$os}->{'AppStore'}->{'uploadApp'}->{'enabled'} && 
                            $json->{$os}->{'AppStore'}->{'title'} == $binTitle) {
                            $itemClassForAppStore = "class=\"item_type2\"";
                            $itemClassForAppStoreDesc = "<!-- 20220119 item_type2 클래스 추가 -->";
                            $uploadAppLink = "appstore_upload.php?title=". $anItem->{'file'};
                            $uploadAppVersion = $finalJson->{'appVersion'} . "." . $finalJson->{'buildVersion'};
                            $appStoreUploadLink = "<a href=\"javascript:appStoreUploading('". $uploadAppLink ."','". $uploadAppVersion ."');\" class=\"btn_$os\">" .strtoupper($os). " 배포 바로가기</a> <!-- 20220119 추가 -->";
                            // TODO: change button link after done uploaded to App Store, need to add AppID('1542294610') into config.json
                            // https://appstoreconnect.apple.com/apps/1542294610/testflight/ios
                        }
                        // Android download AAB Bundle and apk
                        if ($os == "android" && $finalJson->{'releaseType'} == 'release' && 
                        $json->{$os}->{'GoogleStore'}->{'usingBundleAAB'} && 
                        $json->{$os}->{'GoogleStore'}->{'title'} == $binTitle) {
                            $itemClassForAppStore = "class=\"item_type2\"";
                            $itemClassForAppStoreDesc = "<!-- 20220119 item_type2 클래스 추가 -->";
                            $appStoreUploadLink = "<a href=\"$finalURL\" class=\"btn_$os\">" .strtoupper($os). " AAB 다운로드</a> <!-- 20220119 추가 -->";
                            $finalURL = str_replace('aab', 'apk', $finalURL);
                        }
                        $finalSnippet .= "
                            <li $itemClassForAppStore> $itemClassForAppStoreDesc
                                <a href=\"$finalURL\" class=\"btn_down\">
                                    <em class=\"txt1\">" . $anItem->{'title'} . "</em>
                                    <span class=\"bar\">|</span>
                                    <span class=\"txt2\">" . $anItem->{'size'} . "</span>               
                                    <span class=\"hide\">다운로드</span>
                                </a>
                                $appStoreUploadLink
                            </li>
                        ";
                    }
                }
                $finalSnippet .= "</ul>";
            }

            $finalSnippet .= "<!-- 히스토리 : 펼침 접힘 토글 -->
      <div class=\"history_area\">
      <button type=\"button\" class=\"btn\">History</button>
      <ul class=\"list\">\n";

            $input = $finalJson->{'gitLastLog'};
            // $ab = htmlentities($input);
            // $input = unescape_unicode($input);
            // $input = preg_replace('//', ' ', $input);
            // $input = preg_replace('/\\\\/', '', $input);
            // $input = preg_replace('/li>n/', 'li>', $input);
            $tmpList = explode('|', $input);
            for ($i = 0; $i < count($tmpList); $i++) {
                $tmpItem = explode('▶︎', $tmpList[$i]);
                $commitId = preg_replace('//', ' ', $tmpItem[0]);
                if (count($tmpItem) > 1) {
                    $comment  = preg_replace('//', ' ', $tmpItem[1]);
                    if (strlen($comment) <= 0) {
                        $comment  = $commitId;
                    }
                    $finalSnippet .= "\t\t<li><span class=\"tit\">$commitId</span><p class=\"txt\">$comment</p></li>\n";
                } else {
                    $finalSnippet .= "\t\t<li><span class=\"tit\">+</span><p class=\"txt\">$commitId</p></li>\n";
                }
            }


            $finalSnippet .= "\n</ul>
      </div>
      <!-- //히스토리 : 펼침 접힘 토글 -->
      </div>
      </div>
      </div>
      <!-- " . $finalJson->{'appVersion'} . "." . $finalJson->{'buildVersion'} . " jenkins(" . $finalJson->{'buildNumber'} . ") END -->
      ";

            // E N D: Make HTML Snippet with JSON data
        }
        // E N D: Fetch JSON data



        if ($isSearch) {
            if ($searchPattern == L::title_tab_qc_version && $typeKey >= 3 &&
                $typeKey != "_del" && $finalJson->{'releaseType'} == 'release') {
                    $content = $finalSnippet;
                    $finalContents = $finalContents . $content;    
            }
            else if (stripos($content, "$searchPattern")) {
                if ($searchPattern == L::title_tab_qc_version && $typeKey < 3) {
                    continue;
                }
                $content = $finalSnippet;
                $finalContents = $finalContents . $content;
            } else {
                continue;
            }
        } else {
            $content = $finalSnippet;
            $finalContents = $finalContents . $content;
        }

        $finalSnippet = "";
    } //foreach

    return $finalContents;
}
function httpPost($url, $headers, $data, $isBianry)
{
    $curl = curl_init($url);
    curl_setopt($curl, CURLOPT_POST, true);
    curl_setopt($curl, CURLOPT_HEADER, false);
    if (isset($headers)) {
        curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
    }
    if ($isBianry) {
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
    } else {
        curl_setopt($curl, CURLOPT_POSTFIELDS, http_build_query($data));
    }
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($curl);
    curl_close($curl);
    return $response;
}
function httpGet($url)
{
    $curl = curl_init($url);
    curl_setopt($curl, CURLOPT_POST, false);
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
    $response = curl_exec($curl);
    curl_close($curl);
    return $response;
}
?>
