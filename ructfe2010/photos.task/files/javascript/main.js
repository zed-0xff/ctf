var countInRow = 4;
var photosInRow = 2;

function update_albums() {
  $('#albums').html('');
  $.post(
    'ajax/albums',
    {},
    function (jalbums) {
      var html = '';
      var htmls = new Array();
      html += '<table align=center>';
      html += '<tr>';
      if (jalbums.albums.length == 0)
        html += '<td class="nophotos">Albums will are here</td>';
      for (i in jalbums.albums) {
        var aid = jalbums.albums[i][0];
        html += "<td width = '" + (100 / countInRow) + "%'><div class='album' id='albums_" + aid + "'></div></td>";
        if (i % countInRow == countInRow - 1)
          html += '</tr><tr>';
        var album_author = jalbums.albums[i][1];
        htmls[aid] = "<table><tr><td><img src = 'files/avatars/" + aid + ".png' width = '128' onclick = 'show_photos(" + aid + ");' /></td><td><div class = 'plus'><img src = 'files/image/plus.png' onclick = 'add_photo_into_album(" + aid + ")'></div></td></tr><tr><td>" + album_author +  "</td></tr></table>";
      }
      html += '</tr>';
      html += '</table>';
      $('#albums').html(html);
      for (i in jalbums.albums)
        $('#albums_' + jalbums.albums[i][0]).html(htmls[jalbums.albums[i][0]]);
    },
    'json');
}

function show_ads(photos)
{
  content = '';
  for (var i in photos)
    content += photos[i][2] + ' ';
  $('#ads').load('/privacy/ads.php?ads=' + escape(content));
}

function update_photos(aid) {
  $.post(
          'ajax/photos',
          { 
            aid : aid
          },
          function(jphotos) {
            if (jphotos.fail == 1)
            {
              $('#show').html('<div class="denied">Permission denied</div>');
              return ;
            }
            var html = '';
            html += "<table width='100%'>";
            html += "<tr><td colspan='" + photosInRow + "' style='text-align:center;'>Author: <b>" + jphotos.album[0][1] + "</b></td></tr>";
            html += "<tr>";
            if (jphotos.photos.length == 0)
              html += '<td colspan=' + photosInRow + ' class="nophotos">No photos... :\'-(</td>';
            for (i in jphotos.photos) {
              var photo_title = jphotos.photos[i][2];
              var photo_src = jphotos.photos[i][3];
              html += "<td><table><tr><td><img src = 'files/photos/" + photo_src + "' width = '240' class='photo' onClick='show_photo(" + jphotos.photos[i][0] + ")'/></td></tr><tr><td>" + photo_title + "</td></tr></table></td>";
              if (i % photosInRow == photosInRow - 1)
                html += "</tr><tr>";
            }
            html += '</tr></table>';  
            $('#show').html(html);
            show_ads(jphotos.photos);
          },
          'json');
}

function update_photo(pid)
{
  hide_all();
  $('#show').animate({opacity: 'show'}, 300);
  $.post(
          'ajax/getcomments',
          { 
            pid : pid
          },
          function(jcomments) {
            if (jcomments.fail == 1)
            {
              $('#show').html('<div class="denied">Permission denied</div>');
              return;
            }
            var html = '';
            html += '<table border=0 cellpadding=0 cellspacing=2 style="padding: 10px">';
            html += '<tr><td><img src="files/photos/' + jcomments.src + '"/></td></tr>';
            if (jcomments.comments.length == 0)
              html += '<tr><td class="nophotos">No comments... :\'-(</td></tr>';
            for (i in jcomments.comments) {
              var comment_author = jcomments.comments[i][0];
              var comment_text = jcomments.comments[i][1];
              html += '<tr><td><b>' + comment_author + '</b>:</td></tr>';
              html += '<tr><td><pre>' + comment_text + '</pre><td><tr>';
              html += '<tr><td>&nbsp;</td></tr>';
            }
            html += '<tr><td>Leave your comment about photo</td></tr>';
            html += '<input type="hidden" name="commentpid" id="commentpid" value="' + pid + '">';
            html += '<tr><td><textarea id="comment" cols=50 rows=4></textarea></td></tr>';
            html += '<tr><td><a class="abutton" onClick="send_comment()">Submit</a></td></tr>';
            html += '</table>';  
            $('#show').html(html);
          },
          'json');  
}

function send_comment()
{
  var pid = $('#commentpid').val();
  var comment = $('#comment').val();
  $.post(
         'ajax/putcomment',
         { 
           pid : pid,
           comment : comment
         },
         function(janswer) {
           if (janswer.fail != 1)
             update_photo(pid);
         },
         'json');
}

function hide_all()
{
  $('#albums').animate({opacity: 'hide'}, 0);
  $('#show').animate({opacity: 'hide'}, 0);
  $('#upload').animate({opacity: 'hide'}, 0);
  $('#login_form').animate({opacity: 'hide'}, 0);
  $('#albums_panel').animate({opacity: 'hide'}, 0);
  $('#create_album').animate({opacity: 'hide'}, 0);
}

function show_upload() {
  hide_all();
  $('#upload').animate({opacity: 'show'}, 300);
  $('#check_upload_form').html('');
  $('#title_input').val('');
}

function show_photos(aid) {
  location.hash = 'photos/' + aid;
}

function show_login_form() {
  hide_all();
  $('#login_form').animate({opacity: 'show'}, 300);
}

function show_albums() {
  hide_all();
  $('#albums').animate({opacity: 'show'}, 300);
  $('#albums_panel').animate({opacity: 'show'}, 300);
  update_albums();
}

function show_photo(pid) {
  location.hash = 'photo/' + pid;
}

function add_photo_into_album(aid) {
  $("#aid").val(aid);
  location.hash = '#upload/' + aid;
}

function upload()
{
  $('#upload_form').submit();
}

function logout_success() {
  javascript:location.reload(true);
}

function logout() {
  $.get(
    'logout',
    {},
    logout_success,
    'json'
  )
}

function create_album() {
    if ($('#album_name').val() == '')
      $('#check_create_form').html('Enter name for album!');
    else if (! $('input[name="mode"]:checked').val())
      $('#check_create_form').html('Choose mode for album!');
    else {
      $.post(
        'ajax/create',
        { 
          mode : $("input[name='mode']:checked").val(),
          name : $('#album_name').val()
        },
        function(json) {      
          location.hash = '#albums';
        },
        'json');
    }
  }

$(document).ready(function() {
  $('#nav_upload').click(show_upload);
  $('#nav_albums').click(function() { location.hash = '#albums'; });
  $('#nav_login').click(function() { location.hash = '#login'; });
  $('#nav_logout').click(logout);
  $('#upload_form_button').click(upload);
  $('#create_album_button').click(function() { location.hash = "#create_album"; });
  $('#form_create_album_button').click(create_album);
  $('#create_album_form').submit(create_album);
  $('#upload_form').submit(function() {
    if ($('#title_input').val() == '') {
      $('#check_upload_form').html('Enter title for photo!');
      return false;
    } else {
      if ($('#file_input').val() == '') {
        $('#check_upload_form').html('Select file for upload!');
        return false;
      } else {
        return true;
      }
    }
  })
  $('#auth_form').submit(function() {
    if ( $('#login').val() == '' ) {
      $('#check_login_form').html('Enter login!');
      return false;
    } else {
      if ( $('#password').val() == '' ) {
        $('#check_login_form').html('Enter password!');
        return false;
      } else {
        return true;
      }
    }
  })
  setInterval(updateHashState, 100);
})

var oldhash = '';

function updateHashState()
{
  var hash = location.hash;
  if (hash == '')
    hash = '#albums';
  if (hash == oldhash)
    return;
  if (hash == '#create_album')
  {
    hide_all();
    $('#albums').animate({opacity:'hide'}, 0);
    $('#album_name').val('');
    $('#create_album').animate({opacity: 'show'}, 300);
  }
  if (hash == '#albums')
    show_albums();
  if (hash == '#login')
    show_login_form();
  if (hash == '#fail')
    location.hash = '#login';
  if (hash.substr(0, 8) == '#upload/') 
    show_upload();
  if (hash.substr(0, 8) == '#photos/')
  {
    var s = hash.split('/');
    if (s.length != 2)
      return;
    var aid = parseInt(s[1]);
    hide_all();
    update_photos(aid);
    $('#show').animate({opacity: 'show'}, 300);
  }
  if (hash.substr(0, 7) == '#photo/')
  {
    var s = hash.split('/');
    if (s.length != 2)
      return;
    var pid = parseInt(s[1]);
    hide_all();
    update_photo(pid);
  }

  oldhash = hash;  
}
