
root = exports ? this

FeltMap = () ->
  width = 1024
  height = 600
  margin = {top: 0, right: 0, bottom: 0, left: 0}
  latValue = (d) -> parseFloat(d.lat)
  lonValue = (d) -> parseFloat(d.lon)
  data = []
  locations = []
  lines = []
  projection = d3.geo.mercator().scale(width).translate([width / 2, height / 2])
  path = d3.geo.path().projection(projection)
  mapG = null
  locG = null
  annoG = null
  linesG = null
  node = null
  annotation = null
  line = null
  map = null
  locationsDivId = null
  lineColor = "#fff"
  nodeColor = "#1F4C59"
  lineSize = 1.3
  mapOpacity = 0.8
  nodeRadius = 4

  zoomer = () ->
    projection.translate(d3.event.translate).scale(d3.event.scale)
    map.attr("d", path)
    update()

  zoom = d3.behavior.zoom()
    .translate(projection.translate())
    .scale(projection.scale())
    .on("zoom", zoomer)

  fmap = (selection) ->
    selection.each (rawData) ->
      width = $(this).width() - 320
      height = $(this).height()
      data = rawData
      svg = d3.select(this).selectAll("svg").data([data])
      gEnter = svg.enter().append("svg")
      svg.attr("width", width + margin.left + margin.right )
        .attr("height", height + margin.top + margin.bottom )

      g = svg.append("g")
        .attr("id", "svg_vis")
        .attr("transform", "translate(#{margin.top},#{margin.left})")

      mapG = g.append("g")
        .attr("id", "countries")
        .call(zoom)

      mapG.append("rect")
        .attr("class", "background")
        .attr("width", width)
        .attr("height", height)
        .attr("pointer-events", "all")

      linesG = g.append("g")
        .attr("id", "lines")

      locG = g.append("g")
        .attr("id", "locations")

      annoG = g.append("g")
        .attr("id", "annotations")

      d3.json "data/countries.geo.json", (json) ->
        drawMap(json)
        update()

  fmap.opacity = (_) ->
    if !arguments.length
      return mapOpacity
    mapOpacity = _
    if map
      map.style("opacity", mapOpacity)
    fmap

  fmap.line = (_) ->
    if !arguments.length
      return lineColor
    lineColor = _
    if line
      line.style("stroke", lineColor)
    fmap

  fmap.node = (_) ->
    if !arguments.length
      return nodeColor
    nodeColor = _
    if node
      node.style("fill", nodeColor)
    if annotation
      annotation.selectAll("line")
        .style("stroke", nodeColor)
      annotation.selectAll("text")
        .style("fill", nodeColor)
    fmap

  fmap.add = (point) ->
    data.push(point)
    update()
    fmap.displayLocations(locationsDivId)
    fmap

  fmap.data = (_) ->
    if !arguments.length
      return data
    data = _
    update()
    fmap.displayLocations(locationsDivId)
    fmap

  fmap.remove = (index) ->
    data.splice(index,1)
    update()
    node.attr("r", 0)
    fmap.displayLocations(locationsDivId)
    fmap
    # data.push(point)
    # update()
    #
  fmap.displayLocations = (id) ->
    locationsDivId = id
    locationsDiv = d3.select(id)

    locationsDiv.selectAll(".location").remove()

    loc = locationsDiv.selectAll(".location")
      .data(data, (d) -> "#{roundNumber(d.lat, 6)},#{roundNumber(d.lon, 6)}")

    row = loc.enter().append("tr")
      .attr("class", "location")
    eyeDet = row.append("td").append("a")
      .attr("href", "#")
      .attr("id", (d,i) -> "show_#{i}")
      .attr("class", (d) -> if d.visible then "active_show_loc show_loc" else "show_loc")
      .on("mouseover", showLocation)
      .on("mouseout", hideLocation)
      .on "click", (d,i) ->
        if d.visible
          d.visible = false
          d3.select(this).select("i").classed("icon-eye-open", false).classed("icon-eye-close",true)
        else
          d.visible = true
          d3.select(this).select("i").classed("icon-eye-open", true).classed("icon-eye-close",false)
        update()
    eyeDet.append("i")
      .attr("class", (d) ->  if d.visible then "active_show_loc show_loc icon-eye-open" else "show_loc icon-eye-close")
    row.append("td")
      .attr("id", (d,i) -> "edit_#{i}")
      .attr("class", "edit_area")
      .text((d) -> d.name or "#{d.lat}, #{d.lon}")
      .on("mouseover", showLocation)
      .on("mouseout", hideLocation)
    delDet = row.append("td")
      .attr("class", "delete_location")
      .append("a")
        .on("mouseover", showLocation)
        .on("mouseout", hideLocation)
        .on("click", (d,i) -> fmap.remove(i))
    delDet.append("i")
      .attr("class", "icon-remove")

    $('.edit_area').editable (value, settings) ->
      index = parseInt(d3.select(this).attr("id").replace("edit_",""))
      data[index].name = value
      return value

    loc.exit().remove()
    fmap

  showLocation = (d,i) ->
    node.filter( (e,n) -> n == i)
      .attr("r", 6)
      .style("fill", "red")

  hideLocation = (d,i) ->
    node
      .attr("r", (n,e) -> if data[e].visible then nodeRadius else 0)
      .style("fill", nodeColor)

  drawMap = (json) ->
    map = mapG.selectAll("path")
      .data(json.features)
    map.enter()
      .append("path")
      # .on("click", click)
    
    map.attr("d", path)
      .style("opacity", mapOpacity)

  setupLocations = () ->
    locations = []
    data.forEach (loc) ->
      locations.push(projection([lonValue(loc), latValue(loc)]))
    locations

  setupLines = () ->
    lines = d3.geom.delaunay(locations)
    lines

  update = () ->
    setupLocations()
    setupLines()

    line = linesG.selectAll("path.link")
      .data(lines)

    line.enter()
      .append("path")
      .attr("class","link")
      .style("fill", "none")
      .style("stroke", lineColor)
      .style("stroke-width", lineSize)
    line.attr("d", (d) -> "M" + d.join("L") + "Z")

    line.exit().remove()

    node = locG.selectAll("circle.location")
      .data(locations)
    node.enter()
      .append("circle")
      .attr("class", "location")
    node.attr("cx", (d) -> d[0])
      .attr("cy", (d) -> d[1])
      .attr("r", (d,i) -> if data[i].visible then nodeRadius else 0)
      .style("fill", nodeColor)

    # annotated_locations = locations.filter (d,i) -> data[i].visible
    # console.log(annotated_locations)

    annotation = annoG.selectAll(".annotation")
      .data(locations)

    annotationE = annotation.enter().append("g")
      .attr("class", "annotation")

    annotation.attr("transform", (d) -> "translate(#{d[0]},#{d[1]})")
      .style("opacity", (d,i) -> if data[i].visible then 1 else 0)

    annotationE.append('text')
      .text((d,i) -> data[i].name or "#{data[i].lat}#{data[i].lon}")
      .attr("dx", -20)
      .attr("dy", -5)
      .attr("text-anchor", "end")
      .attr("fill", nodeColor)

    annotationE.append("line")
      .attr("x1", 0)
      .attr("y1", 0)
      .attr("x2", (d,i) -> -20 - 8 * name(data[i]).length)
      .attr("y2", 0)
      .attr("stroke", nodeColor)
      .style("stroke-dasharray", "2, 2")

    annotation.exit().remove()

  name = (d) ->
    d.name or "#{d.lat}#{d.lon}"

  click = (d) ->
    centroid = path.centroid(d)
    translate = projection.translate()
    projection.translate([
      translate[0] - centroid[0] + width / 2,
      translate[1] - centroid[1] + height / 2
    ])

    zoom.translate(projection.translate())
    map.transition()
      .duration(1000)
      .attr("d", path)
  
    update()


  fmap.height = (_) ->
    if !arguments.length
      return height
    height = _
    chart

  fmap.width = (_) ->
    if !arguments.length
      return width
    width = _
    chart

  fmap.margin = (_) ->
    if !arguments.length
      return margin
    margin = _
    chart

  return fmap


plotData = (selector, data, plot) ->
  d3.select(selector)
    .datum(data)
    .call(plot)

setBackground = (newBackground) ->
  $('body').css({"background-color":newBackground})

$ ->
  if document.location.hash
    loaded_options = rison.decode(document.location.hash.replace(/^#/,""))
  else
    loaded_options = {}
  options =
    opacity:loaded_options.opacity or 0.5
    line:loaded_options.line or "FFFFFF"
    background:loaded_options.background or "198587"
    annotation:loaded_options.annotation or "09161A"

  options.background = "#{options.background}"
  options.line = "#{options.line}"

  map = FeltMap().opacity(options.opacity)
    .line(options.line).node(options.annotation)

  setBackground(options.background)

  loaded_data = loaded_options.data

  if loaded_data
    console.log('loading data from url')
    plotData("#vis", loaded_data, map)
    map.displayLocations("#all_locations")
  else
    d3.csv "data/locations.csv", (data) ->
      plotData("#vis", data, map)
      map.displayLocations("#all_locations")
      false

  d3.select("#mapOpacity").on "change", (d) ->
    newOpacity = parseFloat(this.value)
    map.opacity(newOpacity)
    options.opacity = newOpacity
  
  addLatLon = (val) ->
    point = val.split(",").map (s) -> parseFloat(s.replace(/\s/g,''))
    point = {"lat": point[0], "lon":point[1]}
    map.add(point)

  addLocation = (val) ->
    encodedVal = encodeURIComponent(val)
    geocoder = new google.maps.Geocoder()
    geocoder.geocode({
      address: val
    }, (results) ->
      if results.length > 0
        name = val.toUpperCase()
        lat = results[0].geometry.location.lat()
        lon = results[0].geometry.location.lng()
        point = {"lat":lat,"lon":lon, "name":name}
        map.add(point)
    )

    # command = "http://nominatim.openstreetmap.org/search?format=json"
    # command += "&q=#{encodedVal}"
    # console.log(command)
    # jQuery.ajax({url:command, dataType: 'jsonp', jsonpCallback:'parseLocationResults'})

  $('#pointSubmit').click (e) ->
    e.preventDefault()
    val = $('#pointInput').val()
    addLocation(val)
    # addLatLon(val)
    $('#pointInput').val("")

  $("#backgroundColor").miniColors({
	  letterCase: 'uppercase',
	  change: (hex, rgb) ->
      setBackground(hex)
      options.background = hex.replace(/#/,'')
  }
  )

  $("#backgroundColor").miniColors('value', options.background)
  
  $("#lineColor").miniColors({
	  letterCase: 'uppercase',
		change: (hex, rgb) ->
      map.line(hex)
      options.line = hex.replace(/#/,'')
  }
  )

  $("#lineColor").miniColors('value', options.line)

  $("#annotationColor").miniColors({
	  letterCase: 'uppercase',
		change: (hex, rgb) ->
      map.node(hex)
      options.annotation = hex.replace(/#/,'')
  }
  )

  $("#annotationColor").miniColors('value', options.annotation)

  $('#clear_all').click (e) ->
    map.data([])

  $('#save_link').click (e) ->
    e.preventDefault()
    options.data = map.data()
    encoded = rison.encode(options)
    document.location.hash = encoded

  $("#examples_link").click (e) ->
    e.preventDefault()
    $("#examples_list").toggle()

  $("#about_link").click (e) ->
    e.preventDefault()
    $("#about_text").toggle()



