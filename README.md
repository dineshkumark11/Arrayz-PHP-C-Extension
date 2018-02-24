# Arrayz-PHP-C-Extension
Arrayz library compiled to C for faster performance and memory. 

Based on zephir.

Usage Instructions:
------------------------

Download : arrayz.so

1. Load the extension and create instance: 
	
	Copy the extensio arrayz.so file into php extension directory.

	To get to know the extension dir, use phpinfo().

	Load the extension in php.ini by add the following line at last.

	**extension = array.so**

	Restart	your apache/lampp server for the extension to load and create instance by following, 

	**$arrayz = new Ordinate\Arrayz;**

2. After instance created,You can use as following,

	**$arrayz($array)->where('id','1')->get();**

3. **get() is required to return the output array/value.**   

Example Array:
--------------

$array = array (
  0 => 
  array (
   'id' =>'11',   
   'Name' =>'Giri',
   'SSN' =>'123524',   
   'street' =>'17 west stree',
   'state' =>'NY',
   'created_date' =>'0000-00-00 00:00:00',
  ),
  1 => 
  array (
   'id' =>'11',   
   'Name' =>'Anna',
   'SSN' =>'56789',   
   'street' =>'18 west stree',
   'state' =>'CA',
   'created_date' =>'0000-00-00 00:00:00',
  ),
);

select_where:
------------
	
      $arrayz($array)->select_where('id,name',['id >' => '90'], TRUE)->limit(2,0)->get();
            
      //Will return the id, name from selected array where id is less than 90
      // And the limit is 2, offset from 0 and TRUE to preserve key.
	
      $arrayz($array)->select_where('id,name', ['id'=> '1'])->get(); 
      
      //Select the key found returns  id, name  and check the condition as id is equal to 1.
      
      $arrayz($array)->select_where('name,state', ['id >' => '1'], TRUE)->order_by('state', 'ASC')->get();
      
      //Preserve the key, select and filter it. Order by the array state
     
select:
-------
	
      $arrayz($array)->select('id,name')->get(); 
      
      //Select the key found returns  id, name

      //When using select with where, passed select key must be in where condition or else will skip the array. 

      //To prevent this, you can chain as like following,

      $arrayz($array)->where('state')->select('Name,SSN')->get();

      //Filtered with where and return the selected keys
          
     $arrayz($array)->select('id,name')->where('state', 'CA')->group_by('state')->get();
     
     //Select the ID and name and check that stats is equal to CA. we can chain almost all methods by this.


pluck:
------    
      $arrayz($array)->pluck('st')->get(); 

      //Support RegEx key which are matching 'st' and returns street, state          
       
      Most usable case is When Posting ($_POST) Iterator based elements. Ex., count_1, count_2

where:
------
      $arrayz($array)->where('id' ,'1')->get(); 

      // Will return the array where matches id is 1 

      $arrayz($array)->where('id' ,'>','3')->get(); 

      //Will return the array where id is greater than 3, =,!=, >, <>, >=, <=, === operators are supported. By default '='.

      $arrayz($array)->where('id' ,'>','3', TRUE)->get();

      //Preserve the actual key

      $arrayz($array)->where(['id >' => '3', 'name'=> 'Giri'])->get();

      //Multiple conditions. Similar to CI query builder where.
    
where_in: 
------
      $arrayz($array)->where_in( 'id', ['1','3'] )->get(); 

      // Will return the array where matches id is 34 and 35

      $arrayz($array)->where_in( 'id', ['1','3'], TRUE )->get(); 

      // Will return the array where matches id is 34 and 35 and preserve the actual key

where_not_in: 
------
      $arrayz($array)->where_not_in( 'id', ['1','3'] )->get(); 

      // Will return the array where not matches id is 34 and 35

      $arrayz($array)->where_not_in( 'id', ['1','3'], FALSE )->get(); 

      // Will return the array where matches id is 34 and 35 and will not preserve the key
      
Update: 
------
      $arrayz($array)->whereNotIn( 'id', ['1','3'] )->update(['status','1'])->get(); 

      // Will update the array by status = 1 in all array members


flat_where:
------
      $arrayz($array)->flat_where('< 12')->get();      
      
      **Flat repersent the single dimensional array. Ex. [1,2,3,4]**
      
      //It will check the all array values less than 12     
      
join:
------
      $arrayz($array)->join($array2, 'id=category_id', 'left')->get();      
      
      **Join $array with $array2 based on their common value
      
      $arrayz($array)->join($array2, 'id=category_id', 'inner')->get();      
      
      //Only matched ids only return
      
      $arrayz($array)->join($array2, 'id')->get();      
      
      //If both have same column, we can pass only one value(optional).
      
      //By default is 'left'
      
group_by: 
---------
      Groupby by mentioned Key, similar to sql;
      
      $arrayz($array)->group_by('id')->get(); 

      // Will return the array group by by fmo id
      //using get_row() with group_by will return the array with 0 index.
      
order_by: 
---------
      Groupby by mentioned Key, similar to sql;
      
      $arrayz($array)->where( ['id >', '2 ])->order_by('name', 'asc')->get(); 

      // Will return the array based on where condition sort the array by the name
      
      $arrayz($array)->select('id')->where('id', '>', '2' ])->order_by('asc')->get(); 
      //Select will return the array of Id. and filtered by where and order by Asc

limit:
------
      $arrayz($array)->limit(10)->get(); 

      //Will return the first 10 elements

      $arrayz($array)->limit( 10, 5)->get(); 

      //Will return the 10 elements after the 5 the index (Offset)

      $arrayz($array)->limit( 10, 5, TRUE)->get(); 

      //Will return the 10 elements after the 5 the index (Offset) Also preserve the actual key. To preserve the actual key we need offset

like:
------
      $arrayz($array)->like('SSN', '01')->get(); 

      //Will return the elements SSN number having 01, in anywhere of the string. similar to %like% in mysql.
      
not_like:
------
      $arrayz($array)->not_like('SSN', '01')->get(); 

      //Will return the elements SSN number NOT having 01, in anywhere of the string. similar to %like% in mysql.      
      
select_min:
----------
      
      $arrayz($array)->select_min('id')->get(); 

      //Will return minimum id value      
      
      $arrayz($array)->select_min('id', TRUE)->get(); 

      //Will return minimum id value's array
      
select_max:
----------
      
      $arrayz($array)->select_max('id')->get(); 

      //Will return maximum id value      
      
      $arrayz($array)->select_max('id', TRUE)->get(); 

      //Will return maximum id value's array           
      
select_avg:
----------
      
      $arrayz($array)->select_avg('id')->get(); 

      //Will return calculate the average of the id as value      

      $arrayz($array)->select_avg('id', 2)->get(); 

      //Will return calculate average of the id and round off it to 2

select_sum:
----------
      
      $arrayz($array)->select_sum('id')->get(); 

      //Will sum the id value 

assign_key:
----------
      
      $arrayz($array)->assign_key('id')->get(); 
      
      //Will return array with key value as 'id' value for associative result array.
      
      $arrayz($array)->assign_key('id', TRUE)->get(); 
      
      //Will array with key value as 'id' value. id will be removed from the array.      

join_each:
----------
      
      $array2 = [ [ 'state' => 'CA'], ['state' => 'NY'] ];
      
      $arrayz($array)->join_each($array2)->get();
      
      Maximum two arrays can be combinable. It required as Join array have equal count of elements.
      
      $arrayz($array)->join_each($array2)->get();
            
      //It will join the each element of the array to appropriate $array      
      
      
distinct:
----------
      
      $arrayz($array)->distinct('id')->get(); 

      //remove duplicate id array and return distinct

get_row:
----------
      
      $arrayz($array)->where('id','<', '2')->get_row(); 

      //Return the single array, similar to limit(1)

toJson:
----------
      
      $arrayz($array)->where('id','<', '2')->toJson(); 

      //Return the output as json_encode

keys:
----
      $arrayz($array)->keys()->get(); 

      //Returns the key of the array. similar to array_keys

values:
-------
      $arrayz($array)->values()->get(); 

      //Returns the values of the array. similar to array_values

count:
------
     $arrayz($array)->count(); 

     //Returns the no of array/elements based on the array. similar to array count()


Also the library version of Arrayz is available in the https://github.com/giriannamalai/Arrayz/ 
