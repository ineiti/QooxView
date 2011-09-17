function print_a(a) {
	var res = "[";
	for (i in a) {
		if (a[i] && a[i].pop) {
			res += i + ":" + print_a(a[i]) + " - ";
		} else {
			res += i + ":" + a[i] + " - ";
		}
	}
	return res + " ]";
};

function dbg(lvl, str) {
	if (lvl <= DBG_LVL) {
		qx.log.Logger.info(str)
	}
};
