part of kakao_map_plugin;

class KakaoMap extends StatefulWidget {
  final MapCreateCallback? onMapCreated;
  final OnMapTap? onMapTap;
  final OnMarkerClick? onMarkerClick;
  final OnMapDoubleTap? onMapDoubleTap;
  final OnCameraIdle? onCameraIdle;
  final OnDragChangeCallback? onDragChangeCallback;
  final OnZoomChangeCallback? onZoomChangeCallback;
  final OnCenterChangeCallback? onCenterChangeCallback;
  final OnBoundsChangeCallback? onBoundsChangeCallback;
  final OnTilesLoadedCallback? onTilesLoadedCallback;
  final bool? mapTypeControl;
  final ControlPosition mapTypeControlPosition;
  final bool? zoomControl;
  final ControlPosition zoomControlPosition;
  final int minLevel;
  final int currentLevel;
  final int maxLevel;
  final LatLng? center;

  final List<Polyline>? polylines;
  final List<Circle>? circles;
  final List<Polygon>? polygons;
  final List<Marker>? markers;
  final List<CustomOverlay>? customOverlays;

  KakaoMap({
    Key? key,
    this.onMapCreated,
    this.onMapTap,
    this.onMarkerClick,
    this.onMapDoubleTap,
    this.onDragChangeCallback,
    this.onCameraIdle,
    this.onZoomChangeCallback,
    this.onCenterChangeCallback,
    this.onBoundsChangeCallback,
    this.onTilesLoadedCallback,
    this.mapTypeControl = false,
    this.mapTypeControlPosition = ControlPosition.TOPRIGHT,
    this.zoomControl = false,
    this.zoomControlPosition = ControlPosition.RIGHT,
    this.minLevel = 0,
    this.currentLevel = 3,
    this.maxLevel = 25,
    this.center,
    this.polylines,
    this.circles,
    this.polygons,
    this.markers,
    this.customOverlays,
  }) : super(key: key);

  @override
  State<KakaoMap> createState() => _KakaoMapState();
}

class _KakaoMapState extends State<KakaoMap> {
  late final KakaoMapController _mapController;

  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: _loadMap(),
      onWebViewCreated: (WebViewController webViewController) {
        _mapController = KakaoMapController(webViewController);
      },
      javascriptMode: JavascriptMode.unrestricted,
      javascriptChannels: _channels,
      debuggingEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory(() => EagerGestureRecognizer()),
      },
    );
  }

  _loadMap() {
    return Uri.dataFromString('''<html lang="en">

<head>
  <meta charset="UTF-8">
  <meta name="viewport"
        content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0" />
  <script type="text/javascript"
          src='https://dapi.kakao.com/v2/maps/sdk.js?autoload=true&appkey=${AuthRepository.instance.appKey}&libraries=services,clusterer,drawing'></script>
</head>

<body style="margin: 0;">
<div id="map" style="width: 100vw; height: 100vh;"></div>

<script>
  let map = null;
  let polylines = [];
  let circles = [];
  let polygons = [];
  let markers = [];
  let customOverlays = [];
  let clusterer = null;
  const defaultCenter = new kakao.maps.LatLng(33.450701, 126.570667);

  function clearPolyline() {
    for (let i = 0; i < polylines.length; i++) {
      polylines[i].setMap(null);
    }

    polylines = [];
  }

  function clearCircle() {
    for (let i = 0; i < circles.length; i++) {
      circles[i].setMap(null);
    }

    circles = [];
  }

  function clearPolygon() {
    for (let i = 0; i < polygons.length; i++) {
      polygons[i].setMap(null);
    }

    polygons = [];
  }

  function clearMarker() {
    for (let i = 0; i < markers.length; i++) {
      markers[i].setMap(null);
    }

    // if (infoWindow != null) infoWindow.close();

    markers = [];
  }

  function clearCustomOverlay() {
    for (let i = 0; i < customOverlays.length; i++) {
      customOverlays[i].setMap(null);
    }

    customOverlays = [];
  }

  function clear() {
    clearPolyline();
    clearCircle();
    clearPolygon();
    clearMarker();
    clearCustomOverlay();
  }

  function addPolyline(callId, points, color, opacity = 1.0, width = 4) {
    let list = JSON.parse(points);
    let paths = [];
    for (let i = 0; i < list.length; i++) {
      paths.push(new kakao.maps.LatLng(list[i].latitude, list[i].longitude));
    }

    // 지도에 표시할 선을 생성합니다
    let polyline = new kakao.maps.Polyline({
      path: paths,
      strokeWeight: width,
      strokeColor: color,
      strokeOpacity: opacity,
      strokeStyle: 'solid'
    });

    polylines.push(polyline);

    // 지도에 선을 표시합니다
    polyline.setMap(map);
  }

  function addCircle(callId, center, radius, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    center = JSON.parse(center);

    // 지도에 표시할 원을 생성합니다
    let circle = new kakao.maps.Circle({
      center: new kakao.maps.LatLng(center.latitude, center.longitude),  // 원의 중심좌표 입니다
      radius: radius, // 미터 단위의 원의 반지름입니다
      strokeWeight: strokeWeight, // 선의 두께입니다
      strokeColor: strokeColor, // 선의 색깔입니다
      strokeOpacity: strokeOpacity, // 선의 불투명도 입니다 1에서 0 사이의 값이며 0에 가까울수록 투명합니다
      strokeStyle: strokeStyle, // 선의 스타일 입니다
      fillColor: fillColor, // 채우기 색깔입니다
      fillOpacity: fillOpacity  // 채우기 불투명도 입니다
    });

    circles.push(circle);

    // 지도에 원을 표시합니다
    circle.setMap(map);
  }

  function addPolygon(callId, points, holes, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    points = JSON.parse(points);
    let paths = [];
    for (let i = 0; i < points.length; i++) {
      paths.push(new kakao.maps.LatLng(points[i].latitude, points[i].longitude));
    }

    holes = JSON.parse(holes);
    if (!empty(holes)) {
      let holePaths = [];

      for (let i = 0; i < holes.length; i++) {
        let array = [];
        for (let j = 0; j < holes[i].length; j++) {
          array.push(new kakao.maps.LatLng(holes[i][j].latitude, holes[i][j].longitude));
        }
        holePaths.push(array);
      }

      return addPolygonWithHole(callId, paths, holePaths, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity);
    }

    return addPolygonWithoutHole(callId, paths, strokeWeight, strokeColor, strokeOpacity, strokeStyle, fillColor, fillOpacity);
  }

  function addPolygonWithoutHole(callId, points, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    // 지도에 표시할 다각형을 생성합니다
    let polygon = new kakao.maps.Polygon({
      path: points, // 그려질 다각형의 좌표 배열입니다
      strokeWeight: strokeWeight, // 선의 두께입니다
      strokeColor: strokeColor, // 선의 색깔입니다
      strokeOpacity: strokeOpacity, // 선의 불투명도 입니다 1에서 0 사이의 값이며 0에 가까울수록 투명합니다
      strokeStyle: strokeStyle, // 선의 스타일입니다
      fillColor: fillColor, // 채우기 색깔입니다
      fillOpacity: fillOpacity // 채우기 불투명도 입니다
    });

    polygons.push(polygon);

    // 지도에 다각형을 표시합니다
    polygon.setMap(map);
  }

  function addPolygonWithHole(callId, points, holes, strokeWeight, strokeColor, strokeOpacity = 1, strokeStyle = 'solid', fillColor = '#FFFFFF', fillOpacity = 0) {
    // 다각형을 생성하고 지도에 표시합니다
    let polygon = new kakao.maps.Polygon({
      map: map,
      path: [points, ...holes], // 좌표 배열의 배열로 하나의 다각형을 표시할 수 있습니다
      strokeWeight: strokeWeight, // 선의 두께입니다
      strokeColor: strokeColor, // 선의 색깔입니다
      strokeOpacity: strokeOpacity, // 선의 불투명도 입니다 1에서 0 사이의 값이며 0에 가까울수록 투명합니다
      fillColor: fillColor, // 채우기 색깔입니다
      fillOpacity: fillOpacity, // 채우기 불투명도 입니다
    });

    polygons.push(polygon);
  }

  function addMarker(markerId, latLng, draggable, width = 24, height = 30, offsetX = 0, offsetY = 0, imageSrc = '', infoWindowText = '', infoWindowRemovable = true, infoWindowFirstShow) {

    latLng = JSON.parse(latLng);
    let markerPosition = new kakao.maps.LatLng(latLng.latitude, latLng.longitude); // 마커가 표시될 위치입니다

    // 마커를 생성합니다
    let marker = new kakao.maps.Marker({
      position: markerPosition,
    });

    marker['id'] = markerId;

    marker.setDraggable(draggable);

    // 마커가 지도 위에 표시되도록 설정합니다
    marker.setMap(map);

    if (imageSrc !== '' && imageSrc !== 'null') {
      let imageSize = new kakao.maps.Size(width, height); // 마커이미지의 크기입니다
      let imageOption = {offset: new kakao.maps.Point(offsetX, offsetY)}; // 마커이미지의 옵션입니다. 마커의 좌표와 일치시킬 이미지 안에서의 좌표를 설정합니다.

      let markerImage = new kakao.maps.MarkerImage(imageSrc, imageSize, imageOption);
      marker.setImage(markerImage);
    }

    markers.push(marker);

    let infoWindow = null
    if (infoWindowText !== '' && infoWindowText !== 'null') {

      // 인포윈도우를 생성하고 지도에 표시합니다
      infoWindow = new kakao.maps.InfoWindow({
        position: markerPosition,
        content: infoWindowText,
        removable: infoWindowRemovable
      });
    }

    if (infoWindowFirstShow) {
      if (infoWindow != null) {
        infoWindow.open(map, marker);
      }
    }

    if (${widget.onMarkerClick != null}) {
      kakao.maps.event.addListener(marker, 'click', function () {
        if (infoWindow != null) {
          infoWindow.open(map, marker);
        }

        // 클릭한 위도, 경도 정보를 가져옵니다
        let latLng = marker.getPosition();

        const clickLatLng = {
          markerId: marker.id,
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        onMarkerClick.postMessage(JSON.stringify(clickLatLng));

      });
    }
  }

  function setMarkerDraggable(markerId, draggable) {

    let marker = null;
    for (let i = 0; i < markers.length; i++) {
      if (markerId === markers[i].markerId) {
        marker = markers[i];
        break;
      }
    }

    if (marker != null) {
      marker.setDraggable(draggable);
    }
  }

  function addClusterer() {
    if (clusterer == null) return;

    clusterer.addMarker(marker);
  }

  function initMarkerClusterer() {
    clusterer = new kakao.maps.MarkerClusterer({
      map: map,
      gridSize: 35,
      averageCenter: true,
      minLevel: 6,
      disableClickZoom: true,
      styles: [{
        width: '53px', height: '52px',
        color: '#fff',
        background: 'url("http://superstorefinder.net/support/wp-content/uploads/2015/07/m1.png") no-repeat',
        textAlign: 'center',
        lineHeight: '54px'
      }]
    });
  }

  function addCustomOverlay(customOverlayId, latLng, content) {
    latLng = JSON.parse(latLng);
    let markerPosition = new kakao.maps.LatLng(latLng.latitude, latLng.longitude); // 마커가 표시될 위치입니다

    var customOverlay = new kakao.maps.CustomOverlay({
      map: map,
      clickable: true,
      content: content,
      position: markerPosition,
      xAnchor: 0.5,
      yAnchor: 1,
      zIndex: 3
    });

    customOverlay.setMap(map);

    customOverlays.push(customOverlay);
  }

  function showInfoWindow(marker, latitude, longitude, contents = '', infoWindowRemovable) {
    let iwPosition = new kakao.maps.LatLng(latitude, longitude);

    // 인포윈도우를 생성하고 지도에 표시합니다
    let infoWindow = new kakao.maps.InfoWindow({
      map: map, // 인포윈도우가 표시될 지도
      position: iwPosition,
      content: contents,
      removable: infoWindowRemovable
    });

    infoWindow.open(map, marker);
  }

  /**
   * 지도의 중심 좌표를 설정한다.
   * @param latitude Number
   * @param longitude Number
   */
  function setCenter(latitude, longitude) {
    map.setCenter(new kakao.maps.LatLng(latitude, longitude));
  }

  /**
   * 지도의 중심 좌표를 반환한다.
   */
  function getCenter() {
    const center = map.getCenter();

    let result = {
      latitude: center.getLat(),
      longitude: center.getLng(),
    };

    if (${Platform.isIOS}) {
      result = JSON.stringify(result);
    }

    return result;
  }

  /**
   * 지도의 확대 수준을 설정한다.
   * MapTypeId 의 종류에 따라 설정 범위가 다르다.
   * SKYVIEW, HYBRID 일 경우 0 ~ 14, ROADMAP 일 경우 1 ~ 14.
   * @param level
   * @param options
   */
  function setLevel(level, options) {
    // 지도 레벨을 4로 설정한다
    map.setLevel(level);

    // // 지도 레벨을 4로 설정하고 특정 좌표를 기준으로 확대 또는 축소되도록 한다
    // map.setLevel(4, {anchor: new kakao.maps.LatLng(33.450705, 126.570677)}, {animate: animate});
    //
    // // setLevel 시 애니메이션 효과 옵션 설정, 기본지속시간은 300ms이다
    // map.setLevel(4, {animate: true});
    //
    // // setLevel 시 애니메이션 효과의 지속시간을 500ms로 설정
    // map.setLevel(4, {
    //     animate: {
    //         duration: 500
    //     }
    // });
  }

  /**
   * 지도의 확대 수준을 반환한다.
   * @return Number
   */
  function getLevel() {
    return map.getLevel();
  }

  /**
   * 지도의 타입을 설정한다.
   * 베이스타입 : ROADMAP, SKYVIEW, HYBRID
   */
  function setMapTypeId(mapTypeId) {
    map.setMapTypeId(mapTypeId);
  }

  function getMapTypeId() {
    return map.getMapTypeId();
  }

  /**
   * 지도에 로드뷰, 교통정보 등의 오버레이 타입의 타일 이미지를 올린다.
   * 로드뷰 타일 이미지를 추가할 경우 RoadviewOverlay 와 동일한 기능을 수행한다.
   * 오버레이타입: OVERLAY, TERRAIN, TRAFFIC, BICYCLE, bicycleHybrid, USE_DISTRICT
   */
  function addOverlayMapTypeId(mapTypeId) {
    map.addOverlayMapTypeId(mapTypeId);
  }

  /**
   * 지도에 로드뷰, 교통정보 등의 오버레이 타입의 타일 이미지를 삭제한다.
   */
  function removeOverlayMapTypeId(mapTypeId) {
    map.removeOverlayMapTypeId(mapTypeId);
  }

  function setDraggable(draggable) {
    map.setDraggable(draggable);
  }

  function getDraggable() {
    return map.getDraggable();
  }

  function setZoomable(zoomable) {
    map.setZoomable(zoomable);
  }

  function getZoomable() {
    return map.getZoomable();
  }

  function setBounds(bounds, paddingTop = 0, paddingRight = 0, paddingBottom = 0, paddingLeft = 0) {
    map.setBounds(bounds, paddingTop, paddingRight, paddingBottom, paddingLeft);
  }

  function getBounds() {
    let bounds = map.getBounds();
    const sw = {
      latitude: bounds.getSouthWest().getLat(),
      longitude: bounds.getSouthWest().getLng(),
    };

    const ne = {
      latitude: bounds.getNorthEast().getLat(),
      longitude: bounds.getNorthEast().getLng(),
    };

    let result = {
      sw: sw,
      ne: ne
    };

    if (${Platform.isIOS}) {
      result = JSON.stringify(result);
    }

    return result;
  }

  function setMinLevel(minLevel) {
    map.setMinLevel(minLevel);
  }

  function setMaxLevel(maxLevel) {
    map.setMaxLevel(maxLevel);
  }

  /**
   * 중심 좌표를 지정한 픽셀 만큼 부드럽게 이동한다.
   * 만약 이동할 거리가 지도 화면의 크기보다 클 경우 애니메이션 없이 이동한다.
   * @param dx Number
   * @param dy Number
   */
  function panBy(dx, dy) {
    map.panBy(dx, dy);
  }

  /**
   * 중심 좌표를 지정한 좌표 또는 영역으로 부드럽게 이동한다. 필요하면 확대 또는 축소도 수행한다.
   * 만약 이동할 거리가 지도 화면의 크기보다 클 경우 애니메이션 없이 이동한다.
   * 첫 번째 매개변수로 좌표나 영역을 지정할 수 있으며,
   * 영역(bounds)을 지정한 경우에만 padding 옵션이 유효하다.
   * padding 값을 지정하면 그 값만큼의 상하좌우 픽셀이 확보된 영역으로 계산되어 이동한다.
   * padding의 기본값은 32.
   * @param latitude
   * @param longitude
   * @param padding Number
   */
  function panTo(latitude, longitude, padding = 32) {
    // 이동할 위도 경도 위치를 생성합니다
    let moveLatLon = new kakao.maps.LatLng(latitude, longitude);

    // 지도 중심을 부드럽게 이동시킵니다
    // 만약 이동할 거리가 지도 화면보다 크면 부드러운 효과 없이 이동합니다
    map.panTo(moveLatLon);
  }

  function fitBounds(points) {
    let list = JSON.parse(points);

    let bounds = new kakao.maps.LatLngBounds();
    for (let i = 0; i < list.length; i++) {
      // LatLngBounds 객체에 좌표를 추가합니다
      bounds.extend(new kakao.maps.LatLng(list[i].latitude, list[i].longitude));
    }

    map.setBounds(bounds);
  }

  /**
   * 지도에 컨트롤을 추가한다.
   * @param isShowZoomControl boolean
   */
  function setZoomControl(isShowZoomControl) {
    if (!isShowZoomControl) return;

    var zoomControl = new kakao.maps.ZoomControl();
    map.addControl(zoomControl, kakao.maps.ControlPosition.RIGHT);
  }

  function relayout() {
    map.relayout();
  }

  window.onload = function () {
    let container = document.getElementById('map');
    let center = defaultCenter;
    if (${widget.center != null}) {
      center = new kakao.maps.LatLng(${widget.center?.latitude}, ${widget.center?.longitude});
    }

    let options = {
      center: center,
      level: ${widget.currentLevel}
    };

    map = new kakao.maps.Map(container, options);

    initMarkerClusterer();

    if (${widget.mapTypeControl}) {
      const mapTypeControl = new kakao.maps.MapTypeControl();
      map.addControl(mapTypeControl, ${widget.mapTypeControlPosition.id});
    }

    if (${widget.zoomControl}) {
      const zoomControl = new kakao.maps.ZoomControl()
      map.addControl(zoomControl, ${widget.zoomControlPosition.id});
    }

    map.setMinLevel(${widget.minLevel});

    map.setMaxLevel(${widget.maxLevel});

    if (${widget.onCenterChangeCallback != null}) {
      // 중심 좌표가 변경되면 발생한다.
      kakao.maps.event.addListener(map, 'center_changed', function () {
        const latLng = map.getCenter();

        const data = {
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        centerChanged.postMessage(JSON.stringify(data));
      });
    }

    if (${widget.onZoomChangeCallback != null}) {
      // 확대 수준이 변경되기 직전 발생한다.
      kakao.maps.event.addListener(map, 'zoom_start', function (mouseEvent) {
        const level = map.getLevel();
        zoomStart.postMessage(JSON.stringify({zoomLevel: level}));
      });

      // 확대 수준이 변경되면 발생한다.
      kakao.maps.event.addListener(map, 'zoom_changed', function (mouseEvent) {
        const level = map.getLevel();
        zoomChanged.postMessage(JSON.stringify({zoomLevel: level}));
      });
    }

    if (${widget.onBoundsChangeCallback != null}) {
      // 지도 영역이 변경되면 발생한다.
      kakao.maps.event.addListener(map, 'bounds_changed', function (mouseEvent) {
        const bounds = getBounds();
        boundsChanged.postMessage(JSON.stringify(bounds));
      });
    }

    // 지도를 클릭하면 발생한다.
    kakao.maps.event.addListener(map, 'click', function (mouseEvent) {
      // 클릭한 위도, 경도 정보를 가져옵니다
      let latLng = mouseEvent.latLng;

      const clickLatLng = {
        latitude: latLng.getLat(),
        longitude: latLng.getLng(),
        zoomLevel: map.getLevel(),
      }

      onMapTap.postMessage(JSON.stringify(clickLatLng));
    });

    // 지도를 더블클릭하면 발생한다.
    kakao.maps.event.addListener(map, 'dblclick', function (mouseEvent) {
      var latLng = mouseEvent.latLng;
      // alert('double click! ' + latLng.toString());

      const clickLatLng = {
        latitude: latLng.getLat(),
        longitude: latLng.getLng(),
        zoomLevel: map.getLevel(),
      }

      onMapDoubleTap.postMessage(JSON.stringify(clickLatLng));
    });

    // 지도를 마우스 오른쪽 버튼으로 클릭하면 발생한다.
    // kakao.maps.event.addListener(map, 'rightclick', function (mouseEvent) {
    //     var latLng = mouseEvent.latLng;
    //     // alert('double click! ' + latLng.toString());
    //
    //     const clickLatLng = {
    //         latitude: latLng.getLat(),
    //         longitude: latLng.getLng(),
    //         zoomLevel: map.getLevel(),
    //     }
    //
    //     onMapRightTap.postMessage(JSON.stringify(clickLatLng));
    // });

    // 지도에서 마우스 커서를 이동하면 발생한다.
    // kakao.maps.event.addListener(map, 'mousemove', function (mouseEvent) {
    //     var latLng = mouseEvent.latLng;
    //     // alert('double click! ' + latLng.toString());
    //
    //     const clickLatLng = {
    //         latitude: latLng.getLat(),
    //         longitude: latLng.getLng(),
    //         zoomLevel: map.getLevel(),
    //     }
    //
    //     mouseMove.postMessage(JSON.stringify(clickLatLng));
    // });

    if (${widget.onDragChangeCallback != null}) {
      // 마우스 드래그로 지도 이동이 완료되었을 때 마지막 파라미터로 넘어온 함수를 호출하도록 이벤트를 등록합니다
      kakao.maps.event.addListener(map, 'dragstart', function () {
        const latLng = map.getCenter();

        const result = {
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        dragStart.postMessage(JSON.stringify(result));
      });

      kakao.maps.event.addListener(map, 'drag', function () {
        const latLng = map.getCenter();

        const result = {
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        drag.postMessage(JSON.stringify(result));
      });

      kakao.maps.event.addListener(map, 'dragend', function () {
        const latLng = map.getCenter();

        const result = {
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        dragEnd.postMessage(JSON.stringify(result));
      });
    }

    // 마우스 드래그로 지도 이동이 완료되었을 때 마지막 파라미터로 넘어온 함수를 호출하도록 이벤트를 등록합니다
    // kakao.maps.event.addListener(map, 'idle', function () {
    //     const latLng = map.getCenter();
    //
    //     const idleLatLng = {
    //         latitude: latLng.getLat(),
    //         longitude: latLng.getLng(),
    //         zoomLevel: map.getLevel(),
    //     }
    //
    //     cameraIdle.postMessage(JSON.stringify(idleLatLng));
    // });

    if (${widget.onTilesLoadedCallback != null}) {
      // 확대수준이 변경되거나 지도가 이동했을때 타일 이미지 로드가 모두 완료되면 발생한다.
      // 지도이동이 미세하기 일어나 타일 이미지 로드가 일어나지 않은경우 발생하지 않는다.
      kakao.maps.event.addListener(map, 'tilesloaded', function () {
        const latLng = map.getCenter();

        const result = {
          latitude: latLng.getLat(),
          longitude: latLng.getLng(),
          zoomLevel: map.getLevel(),
        }

        tilesLoaded.postMessage(JSON.stringify(result));
      });
    }

    // 지도 기본 타일(일반지도, 스카이뷰, 하이브리드)이 변경되면 발생한다.
    // kakao.maps.event.addListener(map, 'maptypeid_changed', function () {
    //     const latLng = map.getCenter();
    //
    //     const idleLatLng = {
    //         latitude: latLng.getLat(),
    //         longitude: latLng.getLng(),
    //         zoomLevel: map.getLevel(),
    //     }
    //
    //     maptypeidChanged.postMessage(JSON.stringify(idleLatLng));
    // });

    map.setCopyrightPosition(kakao.maps.CopyrightPosition.BOTTOMRIGHT, false)

    onMapCreated.postMessage({"test": 1});
  }

  /****************************************************************************************************
   * 라이브러리 함수 호출
   ***************************************************************************************************/
    function keywordSearch() {
        var places = new kakao.maps.services.Places();

        var callback = function(result, status) {
            console.log(status);
            console.log(result);
        };

        places.keywordSearch('판교 치킨', callback);
    }
    
    // function categorySearch() {
    //     var places = new kakao.maps.services.Places();
    //
    //     var callback = function(result, status) {
    //             console.log(result);
    //     };
    //    
    //     places.categorySearch('BK9', callback);
    // }
    //
    // function addressSearch() {
    //     var geocoder = new kakao.maps.services.Geocoder();
    //
    //     var callback = function(result, status) {
    //             console.log(status);
    //             console.log(result);
    //     };
    //    
    //     geocoder.addressSearch('해남군 송지면', callback);
    // }
    //
    // function coord2Address(latitude, longitude) {
    //     var geocoder = new kakao.maps.services.Geocoder();
    //     // var coord = new kakao.maps.LatLng(37.56496830314491, 126.93990862062978);
    //     // var callback = function(result, status) {
    //     //     if (status === kakao.maps.services.Status.OK) {
    //     //         console.log('그런 너를 마주칠까 ' + result[0].address.address_name + '을 못가');
    //     //     }
    //     // };
    //    
    //     console.log(latitude);
    //     geocoder.coord2Address(longitude, latitude, function(result, status) {
    //        // if (status === kakao.maps.services.Status.OK) {
    //        //      console.log('그런 너를 마주칠까 ' + result[0].address.address_name + '을 못가');
    //        //  }
    //       
    //        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>>> !!!!!!!!!!!!!!!!!!!!!!');
    //        console.log(result);
    //        console.log(status);
    //
    //     });
    // }
    //
    // function coord2RegionCode(latitude, longitude) {
    //     var geocoder = new kakao.maps.services.Geocoder();
    //     // var coord = new kakao.maps.LatLng(37.56496830314491, 126.93990862062978);
    //     // var callback = function(result, status) {
    //     //     if (status === kakao.maps.services.Status.OK) {
    //     //         console.log('그런 너를 마주칠까 ' + result[0].address.address_name + '을 못가');
    //     //     }
    //     // };
    //    
    //     console.log(latitude);
    //     geocoder.coord2Address(longitude, latitude, function(result, status) {
    //        // if (status === kakao.maps.services.Status.OK) {
    //        //      console.log('그런 너를 마주칠까 ' + result[0].address.address_name + '을 못가');
    //        //  }
    //       
    //        console.log('>>>>>>>>>>>>>>>>>>>>>>>>>>> !!!!!!!!!!!!!!!!!!!!!!');
    //        console.log(result);
    //        console.log(status);
    //
    //     });
    // }
    //
    // function transCoord(wtmX, wtmY) {
    //     var geocoder = new kakao.maps.services.Geocoder(),
    //         wtmX = 160082.538257218,
    //         wtmY = -4680.975749087054;
    //     
    //     var callback = function(result, status) {
    //         if (status === kakao.maps.services.Status.OK) {
    //             console.log(result[0].x); // 126.570667
    //             console.log(result[0].y); // 33.45070100000001
    //         }
    //     };
    //     
    //     // WTM 좌표를 WGS84 좌표계의 좌표로 변환한다
    //     geocoder.transCoord(wtmX, wtmY, callback, {
    //         input_coord: kakao.maps.services.Coords.WTM,
    //         output_coord: kakao.maps.services.Coords.WGS84
    //     });
    // }

  const empty = (value) => {
      if (value === null) return true
      if (typeof value === 'undefined') return true
      if (typeof value === 'string' && value === '' && value === 'null') return true
      if (Array.isArray(value) && value.length < 1) return true
      if (typeof value === 'object' && value.constructor.name === 'Object' && Object.keys(value).length < 1 && Object.getOwnPropertyNames(value) < 1) return true
      if (typeof value === 'object' && value.constructor.name === 'String' && Object.keys(value).length < 1) return true // new String
      return false
    }

</script>
</body>

</html>
''', mimeType: 'text/html', encoding: Encoding.getByName('utf-8')).toString();
  }

  @override
  void didUpdateWidget(KakaoMap oldWidget) {
    _mapController.addPolyline(polylines: widget.polylines);
    _mapController.addCircle(circles: widget.circles);
    _mapController.addPolygon(polygons: widget.polygons);
    _mapController.addMarker(markers: widget.markers);
    _mapController.addCustomOverlay(customOverlays: widget.customOverlays);
    super.didUpdateWidget(oldWidget);
  }

  Set<JavascriptChannel>? get _channels {
    Set<JavascriptChannel>? channels = {};

    channels.add(JavascriptChannel(
        name: 'onMapCreated',
        onMessageReceived: (JavascriptMessage result) {
          if (widget.onMapCreated != null) widget.onMapCreated!(_mapController);
        }));

    channels.add(JavascriptChannel(
        name: 'onMapTap',
        onMessageReceived: (JavascriptMessage result) {
          if (widget.onMapTap != null) widget.onMapTap!(LatLng.fromJson(jsonDecode(result.message)));
        }));

    channels.add(JavascriptChannel(
        name: 'onMapDoubleTap',
        onMessageReceived: (JavascriptMessage result) {
          if (widget.onMapDoubleTap != null) widget.onMapDoubleTap!(LatLng.fromJson(jsonDecode(result.message)));
        }));

    channels.add(JavascriptChannel(
        name: 'onMarkerClick',
        onMessageReceived: (JavascriptMessage result) {
          print(result);
          if (widget.onMarkerClick != null) {
            widget.onMarkerClick!(
              jsonDecode(result.message)['markerId'],
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'zoomStart',
        onMessageReceived: (JavascriptMessage result) {
          print("zoomStart ${result.message}");
          if (widget.onZoomChangeCallback != null) {
            widget.onZoomChangeCallback!(
              jsonDecode(result.message)['zoomLevel'],
              ZoomType.start,
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'zoomChanged',
        onMessageReceived: (JavascriptMessage result) {
          print("zoomChanged ${result.message}");
          if (widget.onZoomChangeCallback != null) {
            widget.onZoomChangeCallback!(
              jsonDecode(result.message)['zoomLevel'],
              ZoomType.end,
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'centerChanged',
        onMessageReceived: (JavascriptMessage result) {
          print("centerChanged ${result.message}");
          if (widget.onCenterChangeCallback != null) {
            widget.onCenterChangeCallback!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'boundsChanged',
        onMessageReceived: (JavascriptMessage result) {
          print("boundsChanged ${result.message}");
          if (widget.onBoundsChangeCallback != null) {
            final latLngBounds = jsonDecode(result.message);

            final sw = latLngBounds['sw'];
            final ne = latLngBounds['ne'];

            widget.onBoundsChangeCallback!(LatLngBounds(
              LatLng(sw['latitude'], sw['longitude']),
              LatLng(ne['latitude'], ne['longitude']),
            ));
          }
        }));

    channels.add(JavascriptChannel(
        name: 'dragStart',
        onMessageReceived: (JavascriptMessage result) {
          print("dragStart ${result.message}");
          if (widget.onDragChangeCallback != null) {
            widget.onDragChangeCallback!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
              DragType.start,
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'drag',
        onMessageReceived: (JavascriptMessage result) {
          print("drag ${result.message}");
          if (widget.onDragChangeCallback != null) {
            widget.onDragChangeCallback!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
              DragType.move,
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'dragEnd',
        onMessageReceived: (JavascriptMessage result) {
          print("dragEnd ${result.message}");
          if (widget.onDragChangeCallback != null) {
            widget.onDragChangeCallback!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
              DragType.end,
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'cameraIdle',
        onMessageReceived: (JavascriptMessage result) {
          print("idle ${result.message}");
          if (widget.onCameraIdle != null) {
            widget.onCameraIdle!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'tilesLoaded',
        onMessageReceived: (JavascriptMessage result) {
          print("tilesLoaded ${result.message}");
          if (widget.onTilesLoadedCallback != null) {
            widget.onTilesLoadedCallback!(
              LatLng.fromJson(jsonDecode(result.message)),
              jsonDecode(result.message)['zoomLevel'],
            );
          }
        }));

    channels.add(JavascriptChannel(
        name: 'maptypeidChanged',
        onMessageReceived: (JavascriptMessage result) {
          print("idle ${result.message}");
          if (widget.onCameraIdle != null) {
            widget.onCameraIdle!(LatLng.fromJson(jsonDecode(result.message)), jsonDecode(result.message)['zoomLevel']);
          }
        }));

    channels.add(JavascriptChannel(
        name: 'coord2Address',
        onMessageReceived: (JavascriptMessage result) {
          print("coord2Address ${result.message}");
          // if (widget.onCameraIdle != null)
          //   widget.onCameraIdle!(LatLng.fromJson(jsonDecode(result.message)), jsonDecode(result.message)['zoomLevel']);
        }));

    return channels;
  }
}
