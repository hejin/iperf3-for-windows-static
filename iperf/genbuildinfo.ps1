
$lastsha = git rev-parse --short HEAD

$merges  = git log vs2013 --merges --pretty=format:"%h %p: %s" | sls "master.*into vs2013" | select -exp line
$lastmerge = $merges[0]
$mergeshasums = ($lastmerge -split ":")[0].Split(" ")
$mergeparents = $mergeshasums[1..($mergeshasums.length-1)]

$basedonmastersha = "?"

ForEach ($parentsha in $mergeparents) {
	$isInMaster = (git branch --contains "$parentsha" --color=never --all | sls "[/\s]master\s*$").length
	If ($isInMaster -gt 0) {
		$basedonmastersha = $parentsha
	}
}

$time = [DateTime]::UtcNow.ToString('r')
$version = "3-$lastsha based on master rev $basedonmastersha built at $time"

$config = Get-Content "src\iperf_config.h" | % {
	if ($_ -Match "^#define VERSION ") {
		echo "#define VERSION `"$version`""
	}
	elseif($_ -Match "^#define PACKAGE_VERSION ") {
		echo "#define PACKAGE_VERSION `"$version`""
	}
	elseif($_ -Match "^#define PACKAGE_STRING ") {
		echo "#define PACKAGE_STRING `"iperf $version`""
	}
	else {
		echo $_
	}
}

Set-Content "src\iperf_config.h" $config
