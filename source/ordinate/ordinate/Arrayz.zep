namespace Ordinate;
/**
* Array as Table
* Contributor - Giri Annamalai M
* Version - 2.0
* Github: https://github.com/giriannamalai/Arrayz/
*/
class Arrayz
{
	protected source;
	protected select_fields;
	protected prior_functions;
	protected worker;
	protected functions;
	protected field_cnt;
	protected conditions;
	protected condition_cnt;
	protected orig_source;

	public function __construct(array a=[])	{	}	

	public function __invoke(array a=[])
	{	
		let this->source = [];
		let this->prior_functions = [];
		let this->worker = [];
		let this->functions = [];
		let this->field_cnt = 0;
		let this->condition_cnt = 0;
		let this->conditions = [];
		if !empty a
		{
			let this->source = a;	
			let this->orig_source = a;	
		}
		return this;
	}		

	/* Assign Select action in the queue */
	public function select(var args1, var flat = null)
	{	
		let this->functions["select"] = "resolve_select";
		let this->worker["select"]["flat"] = (flat==null ? false : flat );
		var select;
		let select = args1;
		if (typeof args1 == "string") {
			let select =  explode(",", args1);			
		}
		let select = array_map("trim",select);		
		let this->field_cnt = (flat==true) ? 1 : 2;
		let this->select_fields = (this->field_cnt == 1 && flat==true) ? select[0] : array_flip(select);		
		return this;
	}

	/* perform Select action */
	public function resolve_select()
	{	
		if this->field_cnt == 1 && this->worker["select"]["flat"]==true
		{	
			var op;
			let op = array_column(this->source, this->select_fields);
			let this->source = op;
		}
		else
		{
			var k, v;
			array temp=[];
			for k,v in this->source {
				let temp[k] = array_intersect_key(v, this->select_fields);
			}
			let this->source = temp;
		}
	}

	/* Assign Select action in the queue */
	public function select_column(var arg1, var arg2=null)
	{				
		let this->functions["select_column"] = "resolve_select_column";
		let this->worker["select_column"] = ["select" : arg1, "key" : ((arg2 !=null) ? arg2 : null)];
		return this;
	}

	/* Perform Select action */
	public function resolve_select_column()
	{		
		var op;
		let op = (this->worker["select_column"]["key"] != null) ? array_column(this->source, this->worker["select_column"]["select"], this->worker["select_column"]["key"]) : array_column(this->source, this->worker["select_column"]["select"]);
		let this->source = op;
	}

	/* Logical operator function for Where based actions */
	public function eq(a, b){ return a == b;}
	public function neq(a, b){ return a != b;}
	public function lt(a, b){ return a < b;}
	public function gt(a, b){ return a > b;}
	public function lteq(a, b){ return a <= b;}
	public function gteq(a, b){ return a >= b;}
	public function eq3(a, b){ return a === b;}
	public function neq3(a, b){ return a !== b;}

	public function where(var arg1, var arg2=null, var arg3 = null, var arg4=null)
	{
		var preserve;
		if typeof arg1 == "string" {
			if arg3==null {				
				let this->conditions[0] = [arg1, "eq", arg2];
				let this->condition_cnt = 1;
				let preserve = (arg3!=null) ? arg3 : true;
			}
			else{
				let preserve = (arg4!=null) ? arg4 : true;	
				let arg2 = this->set_func(arg2);
				let this->conditions[0] = [arg1, arg2, arg3];
				let this->condition_cnt = 1;
			}
		}else{
			let this->conditions = this->format_conditions(arg1);
			let preserve = (arg2 != null) ? arg2 : false;
			let this->condition_cnt = count(this->conditions)>1 ? 2 : 1;
		}		
		let this->prior_functions["where"] = "resolve_where";
		let this->worker["where"]["preserve"] = preserve;		
		return this;
	}

	public function resolve_where()
	{
		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_".this->field_cnt.this->condition_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			var func = "";
			let func = "whr_".this->condition_cnt;			
			this->{func}();
		}
		let this->source = (this->worker["where"]["preserve"]==true) ? this->source : array_values(this->source);
	}

	/* Where count 1 */ 
	private function whr_1()
	{
		var k,v, fname;		
		array op = [];
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2]) == true {
				let op[k] = v;
			}
		}
		let this->source = op;
	}

	/* Where count more than 1 */ 
	private function whr_2()
	{
		var k,v,i,j,fname;	
		array op = [];	
		var resp;
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			
			if resp==true {
				let op[k] = v;
			}			
		}
		let this->source = op;
	}

	/* Where Field count1 condition count 1 */ 
	private function where_11()
	{
		array op = [];
		var k,v, fname;
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2])  == true {
				let op[k] = v[this->select_fields];
			}
		}
		let this->source = op;
	}

	private function where_21()
	{
		array op = [];
		var k,v,fname;
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2])  == true {
				let op[k] = array_intersect_key(v, this->select_fields);
			}
		}
		let this->source = op;
	}

	private function where_12() 
	{
		array op=[];
		var k,v, i,j, fname;
		var resp;
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			if resp==true {
				let op[k] = v[this->select_fields];
			}
		}
		let this->source = op;
	}

	private function where_22()
	{
		array op=[];
		var k,v, i,j, fname;
		var resp;	
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			if resp == true {
				let op[k] = array_intersect_key(v, this->select_fields);
			}
		}
		let this->source = op;
	}

	public function resolve_where_row()
	{
		if isset this->functions["order_by"] && this->worker["order_by"]["is_flat"] == false
		{
			this->resolve_order_by();
			unset(this->functions["order_by"]);
		}

		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_row_".this->field_cnt.this->condition_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			var func = "";
			let func = "whr_row_".this->condition_cnt;			
			this->{func}();
		}
		let this->source = (this->worker["where"]["preserve"]==true) ? this->source : array_values(this->source);
	}

		/* Where count 1 */ 
	private function whr_row_1()
	{
		var k,v, fname;		
		array op = [];
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2]) == true {
				let op[k] = v;
				break;
			}
		}
		let this->source = op;
	}

	/* Where count more than 1 */ 
	private function whr_row_2()
	{
		var k,v,i,j,fname;	
		array op = [];	
		var resp;
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			
			if resp==true {
				let op[k] = v;
				break;
			}			
		}
		let this->source = op;
	}

	/* Where Field count1 condition count 1 */ 
	private function where_row_11()
	{
		array op = [];
		var k,v, fname;
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2])  == true {
				let op[k] = v[this->select_fields];
				break;
			}
		}
		let this->source = op;
	}

	private function where_row_21()
	{
		array op = [];
		var k,v,fname;
		let fname = this->conditions[0][1];
		for k,v in this->source {
			if this->{fname}(v[this->conditions[0][0]], this->conditions[0][2])  == true {
				let op[k] = array_intersect_key(v, this->select_fields);
				break;
			}
		}
		let this->source = op;
	}

	private function where_row_12() 
	{
		array op=[];
		var k,v, i,j, fname;
		var resp;
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			if resp==true {
				let op[k] = v[this->select_fields];
				break;
			}
		}
		let this->source = op;
	}

	private function where_row_22()
	{
		array op=[];
		var k,v, i,j, fname;
		var resp;	
		for k,v in this->source {
			let resp = false;
			for i,j in this->conditions {
				let fname = j[1];
				let resp = this->{fname}(v[j[0]], j[2]);
				if resp==false {
					break;
				}
			}
			if resp == true {
				let op[k] = array_intersect_key(v, this->select_fields);
				break;
			}
		}
		let this->source = op;
	}


	private function format_conditions(var cond)
	{		
		array o = []; 
		int i = 0;
		var k,v,x;
		for k,v in cond {
			let x = array_map("trim", explode(" ", k));
			let x[1] = isset(x[1]) ? x[1] : '=';			
			let x[1] = this->set_func(x[1]);			
			let o[i] = [x[0], x[1], v];
			let i = i+1;
		}		
		return o;
	}

	public function set_func(operator)
	{
		string eq;
		switch (operator) {
			case "=":
			case "==":  let eq = "eq";break;
			case "!=":	let eq = "neq";break;
			case "<>":  let eq = "neq";break;
			case "<":   let eq = "lt";break;
			case ">":   let eq = "gt";break;
			case "<=":  let eq = "lteq";break;
			case ">=":  let eq = "gteq";break;
			case "===": let eq = "eq3";break;
			case "!==": let eq = "neq3";break;
			default: let eq = "eq"; break;
		}
		return eq;
	}

	public function whereIn(var arg1, var arg2, var arg3=null)
	{		
		let this->worker["whereIn"] = ["search_key" : arg1, "search_value" : arg2,"preserve" : (arg3!=null) ? arg3 : true];
		let this->prior_functions["whereIn"] = "resolve_whereIn";
		return this;
	}	

	public function where_in(var arg1, var arg2, var arg3=null)
	{		
		let this->worker["whereIn"] = ["search_key" : arg1, "search_value" : arg2,"preserve" : (arg3!=null) ? arg3 : true];
		let this->prior_functions["whereIn"] = "resolve_whereIn";
		return this;
	}

	public function whereNotIn(var arg1, var arg2, var arg3=null)
	{		
		let this->worker["whereIn"] = ["search_key" : arg1, "search_value" : arg2,"preserve" : (arg3!=null) ? arg3 : true];
		let this->prior_functions["whereNotIn"] = "resolve_whereNotIn";
		return this;
	}	

	public function where_not_in(var arg1, var arg2, var arg3=null)
	{		
		let this->worker["whereIn"] = ["search_key" : arg1, "search_value" : arg2,"preserve" : (arg3!=null) ? arg3 : true];
		let this->prior_functions["whereNotIn"] = "resolve_whereNotIn";
		return this;
	}

	public function resolve_whereIn()
	{
		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_in_".this->field_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			
			array op = [];
			var k,v, skey, svalue;
			let skey = this->worker["whereIn"]["search_key"];
			let svalue = array_flip(this->worker["whereIn"]["search_value"]);
			for k,v in this->source {
				if isset(svalue[v[skey]]) {
					let op[k] = v;
				}
			}
			let this->source = op;
		}
		let this->source = (this->worker["whereIn"]["preserve"]==true) ? this->source : array_values(this->source);
	}

	private function where_in_1()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if isset(svalue[v[skey]]) {
				let op[k] = v[this->select_fields];
			}
		}
		let this->source = op;
	}

	private function where_in_2()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if isset(svalue[v[skey]]) {
				let op[k] = array_intersect_key(v, this->select_fields);
			}
		}
		let this->source = op;
	}

	public function resolve_whereNotIn()
	{
		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_not_in_".this->field_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			
			array op = [];
			var k,v, skey, svalue;
			let skey = this->worker["whereNotIn"]["search_key"];
			let svalue = array_flip(this->worker["whereNotIn"]["search_value"]);
			for k,v in this->source {
				if !isset(svalue[v[skey]]) {
					let op[k] = v;
				}
			}
			let this->source = op;
		}
		let this->source = (this->worker["whereNotIn"]["preserve"]==true) ? this->source : array_values(this->source);
	}

	private function where_not_in_1()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereNotIn"]["search_key"];
		let svalue = array_flip(this->worker["whereNotIn"]["search_value"]);
		for k,v in this->source {
			if !isset(svalue[v[skey]]) {
				let op[k] = v[this->select_fields];
			}
		}
		let this->source = op;
	}

	private function where_not_in_2()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if !isset(svalue[v[skey]]) {
				let op[k] = array_intersect_key(v, this->select_fields);
			}
		}
		let this->source = op;
	}

	public function resolve_whereIn_row()
	{
		if isset this->functions["order_by"]
		{
			this->resolve_order_by();
			unset(this->functions["order_by"]);
		}

		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_in_row".this->field_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			
			array op = [];
			var k,v, skey, svalue;
			let skey = this->worker["whereIn"]["search_key"];
			let svalue = array_flip(this->worker["whereIn"]["search_value"]);
			for k,v in this->source {
				if isset(svalue[v[skey]]) {
					let op[k] = v;
					break;
				}
			}
			let this->source = op;
		}
		let this->source = (this->worker["whereIn"]["preserve"]==true) ? this->source : array_values(this->source);
	}

	private function where_in_row1()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if isset(svalue[v[skey]]) {
				let op[k] = v[this->select_fields];
				break;
			}
		}
		let this->source = op;
	}

	private function where_in_row2()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if isset(svalue[v[skey]]) {
				let op[k] = array_intersect_key(v, this->select_fields);
				break;
			}
		}
		let this->source = op;
	}

	public function resolve_whereNotIn_row()
	{
		if isset this->functions["order_by"]
		{
			this->resolve_order_by();
			unset(this->functions["order_by"]);
		}

		if isset this->worker["select"] {
			var func="";
			/*Complete Dynamic approach*/
			let func = "where_not_in_row_".this->field_cnt;
			this->{func}();		
			unset(this->functions["select"]);		
		}else {
			
			array op = [];
			var k,v, skey, svalue;
			let skey = this->worker["whereNotIn"]["search_key"];
			let svalue = array_flip(this->worker["whereNotIn"]["search_value"]);
			for k,v in this->source {
				if !isset(svalue[v[skey]]) {
					let op[k] = v;
					break;
				}
			}
			let this->source = op;
		}
		let this->source = (this->worker["whereNotIn"]["preserve"]==true) ? this->source : array_values(this->source);
	}

	private function where_not_in_row_1()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereNotIn"]["search_key"];
		let svalue = array_flip(this->worker["whereNotIn"]["search_value"]);
		for k,v in this->source {
			if !isset(svalue[v[skey]]) {
				let op[k] = v[this->select_fields];
				break;
			}
		}
		let this->source = op;
	}

	private function where_not_in_row_2()
	{
		array op = [];
		var k,v, skey, svalue;
		let skey = this->worker["whereIn"]["search_key"];
		let svalue = array_flip(this->worker["whereIn"]["search_value"]);
		for k,v in this->source {
			if !isset(svalue[v[skey]]) {
				let op[k] = array_intersect_key(v, this->select_fields);
				break;
			}
		}
		let this->source = op;
	}

	public function group_by(var arg1)
	{		
		let this->worker["group_by"] = ["grp_by" : arg1];
		let this->functions["group_by"] = "resolve_group_by";
		return this;		
	}	

	public function resolve_group_by()
	{
		array op = [];
		var grp_by, data, grp_val;
		let grp_by = this->worker["group_by"]["grp_by"];
		for data in this->source {
			let grp_val = data[grp_by];
			if isset(op[grp_val]) {
			   let op[grp_val][] = data;
			} else {
			   let op[grp_val] = [data];
			}
		}	
		let this->source = op;
	}

	public function limit(var arg1, var arg2=0, var arg3=true)
	{		
		let this->worker["limit"] = ["limit" : (arg1 !=1 ? arg1+1 : arg1) , "offset" : arg2, "preserve" : arg3];
		let this->functions["limit"] = "resolve_limit";
		return this;
	}
	
	public function resolve_limit()
	{
		var offset, limit, preserve;
		
		let offset = this->worker["limit"]["offset"];
		let limit = this->worker["limit"]["limit"];
		let preserve = this->worker["limit"]["preserve"];
		let this->source = array_slice(this->source, offset, limit, preserve);		
		let this->source = (limit == 1 && offset == 0) ? array_values(this->source)[0] : this->source;
	}

	public function flat_where(var arg1, var arg2=true)
	{		
		var cond;
		let cond = array_map("trim", explode(" ", arg1));
		let cond[0] = this->set_func(cond[0]);
		let this->worker["flat_where"] = ["cond" : cond, "preserve" : arg2];		
		let this->functions["flat_where"] = "resolve_flat_where";
		return this;		
	}

	public function resolve_flat_where()
	{
		array op = [];
		var v,k, cond, preserve, fname;
		let cond = this->worker["flat_where"]["cond"];
		let preserve = this->worker["flat_where"]["preserve"];
		let fname = cond[0];		
		for k,v in this->source {			
			if this->{fname}(v, cond[1]) {
				let op[k] = v;
			}
		}		
		let this->source = (preserve==true) ? op : array_values(op);		
	}

	public function resolve_flat_where_row()
	{
		if isset this->functions["order_by"] && this->worker["order_by"]["is_flat"] == false
		{
			this->resolve_order_by();
			unset(this->functions["order_by"]);
		}
		array op = [];
		var v,k, cond, preserve, fname;
		let cond = this->worker["flat_where"]["cond"];
		let preserve = this->worker["flat_where"]["preserve"];
		let fname = cond[0];
		for k,v in this->source {
			if this->{fname}(v, cond[1]) {
				let op[k] = v;
				break;
			}
		}
		let this->source = (preserve==true) ? op : array_values(op);			
	}

	public function order_by(var arg1, var arg2=null)
	{
		let this->worker["order_by"] = ["arg1" : arg1, "arg2" : arg2,  "is_flat" : (arg2 != null && !is_bool(arg2)) ? false : true];
		let this->functions["order_by"] = "resolve_order_by";
		return this;
	}

	public function resolve_order_by()
	{
		var arg1,arg2, is_flat, sort_order, fname;
		let arg1 = this->worker["order_by"]["arg1"];
		let arg2 = this->worker["order_by"]["arg2"];
		let is_flat = this->worker["order_by"]["is_flat"];

		if isset this->source[0] && typeof this->source[0] =="array" {	
			let sort_order = ["asc" : "asc_multisort" , "desc" :"desc_multisort"];			
			let arg2 = arg2!=null ? arg2 : "asc";			
			let fname = sort_order[strtolower(arg2)];
			echo fname."\n";
			this->{fname}(arg1);
		}
		else {
			var args_sort,fname;
			let args_sort = strtolower(arg1);			
			let sort_order = ["asc" : "asc_order_by", "desc" : "desc_order_by"];
			let fname = sort_order[args_sort];
			this->{fname}();			
		}
	}

	public function asc_order_by()
	{
		var i,cnt,temp;
		let cnt = range(1,count(this->source));
		let this->source = array_values(this->source);		
		for _ in cnt {
			let i=0;
			for _ in cnt {
				if isset(this->source[i+1]) {
					if this->source[i] > this->source[i+1] {
						let temp = this->source[i+1];
						let this->source[i+1] = this->source[i];
						let this->source[i] = temp;
					}
				}
				let i = i+1;
			}
		}
	}	

	public function desc_order_by()
	{
		var i,cnt,temp;
		let cnt = range(1,count(this->source));	
		let this->source = array_values(this->source);	
		for _ in cnt {
			let i=0;
			for _ in cnt {
				if isset(this->source[i+1]) {
					if this->source[i] < this->source[i+1] {
						let temp = this->source[i+1];
						let this->source[i+1] = this->source[i];
						let this->source[i] = temp;
					}					
				}
				let i = i+1;
			}
		}
	}	

	public function asc_multisort(var sort_by)
	{
		var i,cnt, temp, src;	
		let cnt = range(1,count(this->source));
		let src = array_values(this->source);		
		for _ in cnt {
			let i=0;
			for _ in cnt {
				if isset src[i+1][sort_by] {
					if src[i][sort_by] > src[i+1][sort_by] {
						let temp = src[i+1];
						let src[i+1] = src[i];
						let src[i] = temp;
					}
				}
				let i = i+1;
			}
		}
		let this->source = src; 
	}	

	public function desc_multisort(var sort_by)
	{
		var i,cnt, temp, src;	
		let cnt = range(1,count(this->source));
		let src = array_values(this->source);		
		for _ in cnt {
			let i=0;
			for _ in cnt {
				if isset src[i+1][sort_by] {
					if src[i][sort_by] < src[i+1][sort_by] {
						let temp = src[i+1];
						let src[i+1] = src[i];
						let src[i] = temp;
					}
				}
				let i = i+1;
			}
		}
		let this->source = src; 		
	}

	public function keys()
	{
		let this->functions["keys"] = "resolve_keys";
		return this;
	}

	public function resolve_keys()
	{
		let this->source = array_keys(this->source);
	}

	public function values()
	{
		let this->functions["values"] = "resolve_values";
		return this;
	}

	public function resolve_values()
	{
		let this->source = array_values(this->source);
	}

	public function select_max(var arg0, var arg1=null)
	{
		let this->worker["select_max"] = ["key" : arg0, "preserve" : arg1 != null ? arg1 : false ];		
		let this->functions["select_max"] = "resolve_select_max";
		return this;
	}

	public function resolve_select_max()
	{
		var find_max_in, k;
		let find_max_in = array_column(this->source, this->worker["select_max"]["key"]);
		let k = (this->worker["select_max"]["preserve"]) ? array_keys(find_max_in, max(find_max_in))[0] : "";		
		let this->source = (this->worker["select_max"]["preserve"]) ? [k : array_values(this->source)[k]] : max(find_max_in);
	}

	public function select_min(var arg0, var arg1=null)
	{
		let this->worker["select_min"] = ["key" : arg0, "preserve" : arg1 != null ? arg1 : false ];
		let this->functions["select_min"] = "resolve_select_min";
		return this;
	}

	public function resolve_select_min()
	{
		var find_min_in, k;
		let find_min_in = array_column(this->source, this->worker["select_min"]["key"]);
		let k = (this->worker["select_min"]["preserve"]) ? array_keys(find_min_in, min(find_min_in))[0] : "";		
		let this->source = (this->worker["select_min"]["preserve"]) ? [k : array_values(this->source)[k]] : min(find_min_in);
	}

	public function select_avg(var arg0, var arg1=null)
	{		
		let this->worker["select_avg"] = ["key" : arg0, "round_off" : arg1 != null ? arg1 : false];
		let this->functions["select_avg"] = "resolve_select_avg";
		return this;
	}

	public function resolve_select_avg()
	{
		let this->source = array_column(this->source, this->worker["select_avg"]["key"]);		
		let this->source = this->worker["select_avg"]["round_off"] != null && is_numeric(this->worker["select_avg"]["round_off"]) ? round((array_sum(this->source)/count(this->source)), this->worker["select_avg"]["round_off"]) : ( array_sum(this->source)/count(this->source) );		
	}

	public function pluck(var arg0)
	{					
		let this->worker["pluck"] = ["search" : arg0];
		let this->functions["pluck"] = "resolve_pluck";	
		return this;	
	}

	public function resolve_pluck()
	{			
		var i,j,k,l,search;
		array op = [];
		let i=0;
		let search = this->worker["pluck"]["search"];
		for j in this->source {
			for k,l in j {
				if strpos(k, search) !== false {
					let op[i] = [k:l];
					let i = i+1;
				}
			}
		}
		let this->source = op;
	}

	public function sum(var arg0)
	{	
		let this->source = array_column(this->source, arg0);
		let this->source = array_sum(this->source);
		return this->source;
	}

	public function like(var arg0, var arg1)
	{	
		let this->worker["like"] = ["search_key" : arg0, "search_value" : arg1];
		let this->functions["like"] = "resolve_like";
		return this;
	}

	public function resolve_like()
	{
		var v, search_key, search_value, k;
		array op = [];
		let search_key = this->worker["like"]["search_key"];
		let search_value = this->worker["like"]["search_value"];
		for k,v in this->source {
			if strpos(v[search_key], search_value) !== false {
				let op[k] = v;
			}
		}
		let this->source = op;
	}

	public function not_like(var arg0, var arg1)
	{	
		let this->worker["not_like"] = ["search_key" : arg0, "search_value" : arg1];
		let this->functions["not_like"] = "resolve_not_like";
		return this;
	}

	public function resolve_not_like()
	{
		var v, search_key, search_value,k;
		array op = [];
		let search_key = this->worker["not_like"]["search_key"];
		let search_value = this->worker["not_like"]["search_value"];
		for k,v in this->source {
			if strpos(v[search_key], search_value) === false {
				let op[k] = v;
			}
		}
		let this->source = op;
	}

	public function select_sum(var arg0)
	{		
		let this->worker["select_sum"] = ["key" : arg0 ];
		let this->functions["select_sum"] = "resolve_select_sum";		
		return this;
	}

	public function resolve_select_sum()
	{			
		let this->source = array_column(this->source, this->worker["select_sum"]["key"]);
		let this->source = array_sum(this->source);
	}

	public function distinct(var arg0)
	{		
		let this->worker["distinct"] = ["key" : arg0];
		let this->functions["distinct"] = "resolve_distinct";					
		return this;
	}

	public function resolve_distinct()
	{		
		var s, v,k, source;
		array op = [];
		let source = this->source;
		let this->source = array_column(this->source, this->worker["distinct"]["key"]);		
		let s = array_values(array_flip(this->source));
		let this->source = s;
		for k,v in this->source {
			let op[k] = source[v];
		}
		let this->source = op;			
	}

	public function _reverse(var arg0=true)
	{			
		let this->worker["reverse"] = ["preserve" : arg0];
		let this->functions["reverse"] = "resolve_reverse";		
		return this;
	}

	public function join_each(var arg0, var arg1=false)
	{		
		let this->worker["join_each"] = ["join1" : arg0, "join2" : arg1];
		let this->functions["join_each"] = "resolve_join_each";
		return this;
	}

	public function resolve_join_each()
	{	
		var join1, join2, i, k,v;
		let join1 = this->worker["join_each"]["join1"];
		let join2 = this->worker["join_each"]["join2"];
		let i=0;
		array op = [];
		if(join2==false)
		{
			var join;
			let join = array_values(join1);
			for k,v in this->source {
				let op[k] = isset(join[i]) ? (v + join[i]) : v;
				let i = i+1;
			}
		}
		else
		{			
			var arr1, arr2;
			let arr1 = array_values(join1);			
			let arr2 = array_values(join2);
			for k,v in this->source {
				let op[k] = (isset(arr1[i]) && isset(arr2[i])) ? (v+arr1[i]) + arr2[i] : v;
			}
		}
		let this->source = op;		
	}	

	public function join(var arg0=[], var arg1=null, var arg2="left")
	{		
		let this->worker["join"] = ["join_array" : arg0, "join_by" : arg1, "join_type": arg2];
		let this->functions["join"] = "resolve_join";
		return this;
	}

	public function resolve_join()
	{
	 	var join_array, join_by, join_type, join_keys, joiner_1, joiner_2, key,value, find;
		array op = [];
		let join_array = this->worker["join"]["join_array"];
		let join_by = this->worker["join"]["join_by"];		
		let join_type = strtolower(this->worker["join"]["join_by"]);
		let join_by = (strpos(join_by, "=") !== false) ? array_map("trim", explode("=", join_by)) :  array_fill(0, 1, this->worker["join"]["join_by"]);
		let join_keys = array_fill_keys(array_keys(join_array[0]), null);
		if strtolower(join_by[0]) == strtolower(join_by[1])
		{
			unset(join_keys[join_by[1]]);			
		}
		let joiner_1 = array_flip(array_column(this->source, join_by[0]));
		let joiner_2 = array_flip(array_column(join_array, join_by[1]));
		for key, value in this->source {
			if isset(value[join_by[0]])  { 
				let find = value[join_by[0]];
				if isset(joiner_2[find]) {
					let op[key] = value + join_array[joiner_2[find]];
				}
				elseif(join_type =="left")
				{
					let op[key] = value + join_keys;
				}
			}		
		}		
		let this->source = op;		
	}

	public function resolve_reverse()
	{			
		let this->source = array_reverse(this->source, this->worker["reverse"]["preserve"]);
	}

	public function assign_key(var arg0, var arg1=null)
	{		
		let this->worker["assign_key"] = ["arg0" : arg0, "arg1" : arg1];
		let this->functions["assign_key"] = "resolve_assign_key";
		return this;
	}
	
	public function resolve_assign_key()
	{
		var to_key, k,v, value;		
		array op = [];
		if isset(this->source[0]) {
			var select, keys;
			let value = this->source[0];			
			if this->worker["assign_key"]["arg1"] !== null {
				let to_key[0] = this->worker["assign_key"]["arg0"];
				let keys = array_keys(value);
				let select = array_diff(keys, to_key);
				let select = array_flip(select);
				for v in this->source {
					let k = v[to_key];
					let op[k] = array_intersect_key(v, select);
				}
			}
			else {
				let to_key = this->worker["assign_key"]["arg0"];
				for v in this->source {
					let k = v[to_key];
					let op[k] = v;
				}
			}
		}
   		let this->source = op;
	}

	public function select_where(var arg0, var arg1, var arg2=true)
	{	
		var select, preserve;	
		let select = array_map("trim", explode(",", arg0));
		let this->select_fields = (count(select) == 1) ? select[0] : array_flip(select);			
		let this->field_cnt = (count(select) == 1) ? 1 : 2;		
		let this->worker["select"] = ["preserve" : (count(select) == 1)];
		let this->functions["select"] = "resolve_select";
		
		let this->conditions = this->format_conditions(arg1);		
		let preserve = arg2;
		let this->condition_cnt = count(this->conditions)==1 ? 1 : 2;
		let this->prior_functions["where"] = "resolve_where";
		let this->worker["where"] = ["preserve" : preserve];	
		return this;
	}

	public function toJson(arg)
	{
		this->resolver();
		return (empty(this->source)) ? null : json_encode(this->source);
	}
	
	public function update(var arg0)
	{		
		let this->worker["update"] = ["update_data" : arg0];
		let this->functions["update"] = "resolve_update";	
		return this;
	}

	public function resolve_update()
	{			
		var k,v, update_data;
		array op = [];
		let update_data = this->worker["update"]["update_data"];
		for k,v in this->source {
			let op[k] = array_replace(v, update_data);
		}		
		let this->source = array_replace(this->orig_source,op);
		return this;
	}

    public function get()
    {
    	this->resolver();
		if typeof this->source == "array" && count(this->source)==0
 	 	{
 	 		return null;
 	 	}		
 	 	if typeof this->source != "array" && this->source == ""
 	 	{
	 	 	return null;
 		}
 		let this->orig_source = [];
    	return this->source;
    }
    public function resolver()
    {
    	var v;
	    for v in this->prior_functions {
	    	this->{v}();
	    }
	    let this->prior_functions = [];	    
	    for v in this->functions {
	    	this->{v}();
	    }
	    let this->functions = [];
	    let this->worker = [];
    }

    public function get_row()
	{		
		if count(this->functions) == 0 && this->prior_functions == 0
		{				
			if typeof this->source == "array" && count(this->source) == 0
			{
				return null;
			}			
			let this->source = current(this->source);
			return this->source;	
		}
		var v, fname;
		for v in this->prior_functions {
			let fname = v."_row";
			this->{fname}();
		}
		let this->prior_functions = [];
		for v in this->functions {
			this->{v}();
		}
		let this->worker = [];
		let this->functions = [];
		let this->orig_source = [];
		if typeof this->source =="array" && count(this->source)==0
		{
			return null;
		}		
		let this->source = current(this->source);
		return this->source;
	}
}