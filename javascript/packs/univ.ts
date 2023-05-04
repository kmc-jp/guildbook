import '../src/univ.scss';

document.addEventListener('DOMContentLoaded', () => {
  var exportBtn = document.querySelector<HTMLButtonElement>('button.btn#export');
  if(exportBtn){
    exportBtn.addEventListener('click', function() {  
      var csvdata = "";
      csvdata += "役員名簿\n";

      var executives = document.querySelector<HTMLTableElement>("table#executives");
      if(executives){
        for (var i=0; i < executives.rows.length; i++) {
          if("outdated" in executives.rows[i].dataset){
            continue;
          }
          for (var j=0; j < executives.rows[i].cells.length; j++) {
            if(i===0){
              csvdata += executives.rows[i].cells[j].innerHTML+",";
            }
            else if (executives.rows[i].cells[j].className.match(/student-number/)){
              csvdata+=executives.rows[i].cells[j].innerHTML.replace(/-/g, '')+",";
            } else if (executives.rows[i].cells[j].className.match(/name/)){
              var name = executives.rows[i].cells[j].innerHTML.match(/<div>(.*)<\/div>/);
              if(name){
                csvdata+=name[1]+",";
              } else {
                csvdata+=",";
              }
            } else if (executives.rows[i].cells[j].className.match(/mail/)){
              var name = executives.rows[i].cells[j].innerHTML.match(/<a.*>(.*)<\/a>/);
              if(name){
                csvdata+=name[1]+",";
              } else {
                csvdata+=",";
              }
            } else{
              csvdata += executives.rows[i].cells[j].innerHTML+",";
            }
          }
          csvdata+="\n"
        }
      }

      csvdata += "\n構成員名簿\n";

      var members = document.querySelector<HTMLTableElement>("table#members");
      if(members){
        for (var i=0; i < members.rows.length; i++) {
          if("outdated" in members.rows[i].dataset){
            continue;
          }
          for (var j=0; j < members.rows[i].cells.length; j++) {
            if(i===0){
              csvdata += members.rows[i].cells[j].innerHTML+",";
            }
            else if (members.rows[i].cells[j].className.match(/student-number/)){
              csvdata+=members.rows[i].cells[j].innerHTML.replace(/-/g, '')+",";
            } else if (members.rows[i].cells[j].className.match(/name/)){
              var name = members.rows[i].cells[j].innerHTML.match(/<div>(.*)<\/div>/);
              if(name){
                csvdata+=name[1]+",";
              } else {
                csvdata+=",";
              }
            } else{
              csvdata += members.rows[i].cells[j].innerHTML+",";
            }
          }
          csvdata+="\n"
        }
      }

      var bom  = new Uint8Array([0xEF, 0xBB, 0xBF]);
      var blob = new Blob([bom, csvdata],{type:"text/csv"});
      var anchor = document.createElement('a');
      anchor.href= URL.createObjectURL(blob);
      anchor.download ="役員名簿.csv";
      anchor.click();
      anchor.remove();
    });
  }
});
