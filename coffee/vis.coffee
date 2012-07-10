
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
  linesG = null
  node = null
  line = null
  map = null
  locationsDivId = null
  lineColor = "#fff"
  nodeColor = "#fff"
  lineSize = 1.3
  mapOpacity = 0.8
  nodeRadius = 0

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
      .data(data, (d) -> "#{d.lat},#{d.lon}")

    loc.enter().append("li")
      .attr("class", "location")
      .text((d) -> "#{d.lat}, #{d.lon}")
      .on("mouseover", showLocation)
      .on("mouseout", hideLocation)
      .append("span")
        .attr("class", "delete_location")
        .append("a")
          .text("X")
          .on("click", (d,i) -> fmap.remove(i))

    loc.exit().remove()
    fmap

  showLocation = (d,i) ->
    node.filter( (e,n) -> n == i).attr("r", 6).style("fill", "red")

  hideLocation = (d,i) ->
    node.attr("r", 0)

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
      .attr("r", nodeRadius)
      .style("fill", nodeColor)

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

  options.background = "#{options.background}"
  options.line = "#{options.line}"

  map = FeltMap().opacity(options.opacity)
    .line(options.line)

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
        lat = results[0].geometry.location.lat()
        lon = results[0].geometry.location.lng()
        point = {"lat":lat,"lon":lon}
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



