//////////////////////////////////////////////////////////////////////////////
// RackMonkey - Know Your Racks - http://www.rackmonkey.org                 //
// Version 1.2.5-1                                                          //
// (C)2004-2009 Will Green (wgreen at users.sourceforge.net)                //
// RackMonkey JavaScript library                                            //
//////////////////////////////////////////////////////////////////////////////

// Sets cookie for the current domain which expires in 30 days
function setCookie(name, value) 
{ 
	var expires = new Date;
	expires.setTime(expires.getTime() + 1000 * 60 * 60 * 24 * 30); // in 30 days
	var thisCookie = name + "=" + escape(value) +  ";expires=" + expires.toGMTString(); 
	document.cookie = thisCookie; 
}

function getCookie(name) 
{
	if (name == "") 
		return "";
	var thisCookie = document.cookie;
 	var cStart = thisCookie.indexOf(name);
 	if (cStart == -1)
		return ""; 
	var cEnd = thisCookie.indexOf(';', cStart);
	if (cEnd == -1) 
		cEnd = thisCookie.length; 
	return unescape(thisCookie.substring(cStart + name.length + 1, cEnd));
}

// reverses the current check state of any checkbox with the specified fieldName
function checkboxInvert(fieldName)
{
	for (i = 0; i < fieldName.length; i++)
	if (fieldName.elements[i].checked == 1)
	{
		fieldName.elements[i].checked = 0;
	}
	else 
		fieldName.elements[i].checked = 1;
}

// remove all the child nodes of the specified node
function removeChildNodes(node)
{
  	while (node.hasChildNodes())
	{
		node.removeChild(node.firstChild);
	}
}

// Invert display style on an element
function showHide(element)
{
	var ele = document.getElementById(element);
	if (!ele)
		return true;
	if (ele.style.display == "none")
		ele.style.display = "block";
	else 
		ele.style.display = "none";
	return true;
}

// Returns true if the pressed key is enter
function pressedEnter(e)
{
	var e = e || window.event;
	var kCode = e.which || e.keyCode;
	if (kCode == 13)
		return true;
	return false;
}

// Confirm deletions
function confirmDel(name)
{
	return confirm("Are you sure you want to delete " + name + "?\nThis cannot be undone.");
}

// Show the notes style key
function showNotesStyleKey()
{
	var notesStyleKey = document.getElementById('notes_style_key');
	if (!notesStyleKey)
		return true;
	notesStyleKey.style.display = "block";
	return true;
}

// Show or hide a button with the id 'filterbutton' and a block called 'filters', remembers setting with cookie - should be made more generic
function showHideFilters()
{
	var filters = document.getElementById('filters');
	var filtersButton = document.getElementById('filterbutton');
	if ((!filters) || (!filtersButton))
		return true;
	if (filters.style.display == "none")
	{
		filters.style.display = "block";
		filtersButton.childNodes[0].nodeValue = "Hide Filters";
		setCookie('filter', 'on');
	}
	else 
    {
		filters.style.display = "none";
		filtersButton.childNodes[0].nodeValue = "Show Filters";
		setCookie('filter', 'off');
	}
	return true;
} 

// Show or hide domains in device table vew - should be made more generic
function showHideDomain()
{
	var spans = document.getElementsByTagName('span');
	if (!spans)
		return true;
	
	var domainSpans = [];
	
	for (var i = 0; i < spans.length; i++)
	{
		if (spans[i].className == 'domainSpan')
			domainSpans.push(spans[i]);
	}
	
	if (!domainSpans[0])
		return true;

	if (domainSpans[0].style.display == "none")
	{
		for (var i = 0; i < domainSpans.length; i++)
		{
			domainSpans[i].style.display = "inline";
		}
		setCookie('showdomain', 'on');
		var link = document.getElementById('domainLink');
		if (link)
			link.title = "Hide domain";
	}
	else 
    {
		for (var i = 0; i < domainSpans.length; i++)
		{
			domainSpans[i].style.display = "none";
		}
		setCookie('showdomain', 'off');
		var link = document.getElementById('domainLink');
		if (link)
			link.title = "Show domain";
	}
	return true;
}

// Search for a device by name
function nameSearch()
{
	var search = document.getElementById('name_search').value; 
	if (search.length > 0) 
	{ 
		window.location = '?view=device&view_type=default_search&device_search='+search; 
		return false;
	} 
}

// Jumpt to a given rack
function rackSelect()
{
	var rackSelect = document.getElementById('rack_dropdown');
	var rackId = rackSelect.options[rackSelect.selectedIndex].value;
	if (rackId != 0)
	{ 
		window.location = '?view=rack&view_type=physical&id='+rackId; 
		return false;
	}
	else
	{
		window.location = '?view=rack&view_type=default'; 
	}
}

// Add option to select
function addOption(selectBoxID, text, value)
{
    var selectBox = document.getElementById(selectBoxID);
	var option = document.createElement("option");
    option.text = text;
    option.value = value;
    selectBox.options.add(option);
}

function setManufacturer(selectedManufacturer)
{
    var manuSelectBox = document.getElementById('hardware_manufacturer');
    
    if (selectedManufacturer) 
    {
        var manuCount = manuSelectBox.options.length;
        for (var i = 0; i < manuCount; ++i)
        {
            if (manuSelectBox.options[i].value == selectedManufacturer)
            {
                manuSelectBox.selectedIndex = i;
            }
        }
    }
}

function populateHardwareModels(selectedModel)
{
    var manuSelectBox = document.getElementById('hardware_manufacturer');
    var modelSelectBox = document.getElementById('hardware_model');
    
    var manufacturerID = manuSelectBox.options[manuSelectBox.selectedIndex].value;
    modelSelectBox.options.length = 0; // clear existing options 
    
    var modelCount = hardwareModelIDs[manufacturerID].length;
    for (var i = 0; i < modelCount; ++i)
    {
        addOption('hardware_model', hardwareModelNames[manufacturerID][i], hardwareModelIDs[manufacturerID][i]);
        if (selectedModel)
        {
            if (hardwareModelIDs[manufacturerID][i] == selectedModel)
                modelSelectBox.selectedIndex = i;
        }
    }
}
