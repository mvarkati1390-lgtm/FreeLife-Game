using UnityEngine;
using System.Collections.Generic;

public class FreeLifeBootstrap : MonoBehaviour
{
    GameObject player, car;
    CharacterController controller;
    Camera cam;
    bool driving, showJobs;
    float carSpeed;
    int cash = 2500, bank = 0;
    bool houseOwned;
    string activeJob = "";
    string notice = "به فری‌لایف خوش آمدی";
    GUIStyle hud, small;
    Vector2 touchMove;
    readonly Dictionary<string, int> jobs = new Dictionary<string, int>
    {
        {"راننده تاکسی",500},{"راننده اتوبوس",700},{"مکانیک",600},{"معلم",550},{"کشاورز",450}
    };
    readonly Dictionary<string, Vector3> jobSpots = new Dictionary<string, Vector3>();
    Vector3 bankSpot = new Vector3(16,0,12);
    Vector3 houseSpot = new Vector3(-18,0,18);

    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void StartGame()
    {
        if (FindObjectOfType<FreeLifeBootstrap>() == null)
            new GameObject("FreeLifeGame").AddComponent<FreeLifeBootstrap>();
    }

    void Start()
    {
        Application.targetFrameRate = 60;
        LoadGame();
        BuildCity();
        BuildPlayer();
        BuildCar();
        BuildPlaces();
        cam = Camera.main;
        if (cam == null) { var c = new GameObject("Main Camera"); cam = c.AddComponent<Camera>(); c.tag = "MainCamera"; }
        cam.transform.position = new Vector3(0,7,-10);
        cam.transform.rotation = Quaternion.Euler(25,0,0);
        hud = new GUIStyle(GUI.skin.label) { fontSize=21, normal={textColor=Color.white} };
        small = new GUIStyle(hud) { fontSize=15 };
    }

    Material Mat(Color c)
    {
        Shader shader = Shader.Find("Standard");
        if (shader == null) shader = Shader.Find("Universal Render Pipeline/Lit");
        var m = new Material(shader); m.color=c; return m;
    }
    GameObject Cube(string n, Vector3 p, Vector3 s, Color c)
    {
        var o=GameObject.CreatePrimitive(PrimitiveType.Cube);
        o.name=n; o.transform.position=p; o.transform.localScale=s;
        o.GetComponent<Renderer>().material=Mat(c); return o;
    }
    void BuildCity()
    {
        Cube("Ground",new Vector3(0,-.3f,0),new Vector3(110,.5f,110),new Color(.25f,.48f,.25f));
        Cube("Main road",new Vector3(0,-.02f,0),new Vector3(12,.08f,105),new Color(.12f,.12f,.13f));
        Cube("Cross road",new Vector3(0,-.01f,12),new Vector3(105,.08f,9),new Color(.12f,.12f,.13f));
        for(int z=-48;z<52;z+=8) Cube("Road marking",new Vector3(0,.04f,z),new Vector3(.18f,.03f,3),Color.white);
        for(int x=-48;x<52;x+=8) Cube("Road marking",new Vector3(x,.04f,12),new Vector3(3,.03f,.18f),Color.white);
        for(int x=-42;x<=42;x+=14)
        for(int z=-38;z<=42;z+=18)
        {
            if(Mathf.Abs(x)<9 || (Mathf.Abs(z-12)<7)) continue;
            float h=Random.Range(5f,14f);
            Cube("City building",new Vector3(x,h/2,z),new Vector3(9,h,10),
                new Color(Random.Range(.35f,.7f),Random.Range(.35f,.65f),Random.Range(.35f,.65f)));
        }
        for(int i=0;i<14;i++)
        {
            float x=(i%2==0)?-8:8, z=-45+i*7;
            var trunk=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            trunk.transform.position=new Vector3(x,1,z); trunk.transform.localScale=new Vector3(.35f,1.5f,.35f);
            trunk.GetComponent<Renderer>().material=Mat(new Color(.35f,.2f,.1f));
            var crown=GameObject.CreatePrimitive(PrimitiveType.Sphere);
            crown.transform.position=new Vector3(x,3.2f,z); crown.transform.localScale=Vector3.one*2.4f;
            crown.GetComponent<Renderer>().material=Mat(new Color(.12f,.42f,.16f));
        }
        // Ambient daylight and a simple sky.
        RenderSettings.ambientLight=new Color(.68f,.68f,.68f);
        var sun=new GameObject("Sun").AddComponent<Light>();
        sun.type=LightType.Directional; sun.intensity=1.15f; sun.transform.rotation=Quaternion.Euler(50,-30,0);
    }
    void BuildPlayer()
    {
        player=GameObject.CreatePrimitive(PrimitiveType.Capsule); player.name="Player";
        player.transform.position=PlayerPrefs.GetFloat("px",-3f)*Vector3.right + Vector3.up + PlayerPrefs.GetFloat("pz",0f)*Vector3.forward;
        player.GetComponent<Renderer>().material=Mat(new Color(.1f,.45f,.85f));
        Destroy(player.GetComponent<Collider>());
        controller=player.AddComponent<CharacterController>();
    }
    void BuildCar()
    {
        car=GameObject.CreatePrimitive(PrimitiveType.Cube); car.name="FreeLife car";
        car.transform.position=new Vector3(3,.65f,0); car.transform.localScale=new Vector3(2,1.1f,4);
        car.GetComponent<Renderer>().material=Mat(new Color(.75f,.12f,.1f));
        for(int side=-1;side<=1;side+=2) for(int z=-1;z<=1;z+=2)
        {
            var w=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            w.transform.SetParent(car.transform); w.transform.localPosition=new Vector3(side*.56f,-.35f,z*.34f);
            w.transform.localRotation=Quaternion.Euler(0,0,90); w.transform.localScale=new Vector3(.35f,.18f,.35f);
            w.GetComponent<Renderer>().material=Mat(Color.black);
        }
    }
    void Place(string name, Vector3 pos, Color color)
    {
        var marker=GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        marker.name=name; marker.transform.position=pos+Vector3.up*.12f;
        marker.transform.localScale=new Vector3(1.5f,.25f,1.5f);
        marker.GetComponent<Renderer>().material=Mat(color);
    }
    void BuildPlaces()
    {
        int i=0;
        foreach(var job in jobs)
        {
            Vector3 p=new Vector3((i%2==0)?-15:15,0,-28+(i/2)*15);
            jobSpots[job.Key]=p; Place("Job: "+job.Key,p,new Color(.9f,.7f,.12f)); i++;
        }
        Place("Bank",bankSpot,new Color(.15f,.55f,.9f));
        Place("House",houseSpot,new Color(.25f,.8f,.4f));
    }
    void Update()
    {
        if(player==null || car==null) return;
        if(!driving)
        {
            float h=Input.GetAxisRaw("Horizontal"), v=Input.GetAxisRaw("Vertical");
            Vector3 move=new Vector3(h,0,v);
            if(move.sqrMagnitude>1) move.Normalize();
            controller.Move(move*5f*Time.deltaTime);
            if(move.sqrMagnitude>.01f) player.transform.forward=move;
            if(Input.GetKeyDown(KeyCode.E)) Interact();
        }
        else
        {
            float throttle=Input.GetAxisRaw("Vertical"), steer=Input.GetAxisRaw("Horizontal");
            carSpeed=Mathf.MoveTowards(carSpeed,throttle*13f,9f*Time.deltaTime);
            car.transform.Rotate(0,steer*carSpeed*4f*Time.deltaTime,0);
            car.transform.position+=car.transform.forward*carSpeed*Time.deltaTime;
            if(Input.GetKeyDown(KeyCode.E)) ExitCar();
        }
        if(Input.GetKeyDown(KeyCode.J)) { showJobs=!showJobs; }
        if(cam)
        {
            Transform target=driving?car.transform:player.transform;
            Vector3 desired=target.position+target.rotation*new Vector3(0,7,-10);
            cam.transform.position=Vector3.Lerp(cam.transform.position,desired,Time.deltaTime*4f);
            cam.transform.LookAt(target.position+Vector3.up);
        }
    }
    float DistanceTo(Vector3 p) { return Vector3.Distance(player.transform.position,new Vector3(p.x,player.transform.position.y,p.z)); }
    string NearbyPlace()
    {
        if(DistanceTo(bankSpot)<4) return "بانک";
        if(DistanceTo(houseSpot)<4) return "خانه";
        foreach(var j in jobSpots) if(DistanceTo(j.Value)<4) return j.Key;
        if(Vector3.Distance(player.transform.position,car.transform.position)<4) return "خودرو";
        return "";
    }
    void Interact()
    {
        string place=NearbyPlace();
        if(place=="خودرو") { driving=true; notice="سوار خودرو شدی"; }
        else if(place=="بانک") { bank+=cash; cash=0; SaveGame(); notice="پول نقد به حساب بانکی واریز شد"; }
        else if(place=="خانه")
        {
            if(houseOwned) notice="این خانه متعلق به توست";
            else if(cash>=1500) { cash-=1500; houseOwned=true; SaveGame(); notice="خانه خریداری شد"; }
            else notice="برای خرید خانه ۱۵۰۰ دلار لازم داری";
        }
        else if(jobs.ContainsKey(place))
        {
            if(activeJob==place) { cash+=jobs[place]; activeJob=""; SaveGame(); notice="شیفت تمام شد؛ دستمزد دریافت کردی"; }
            else { activeJob=place; notice="شغل انتخاب شد: "+place+"؛ برای دریافت دستمزد دوباره تعامل کن"; }
        }
        else notice="نزدیک یک خودرو، محل کار، بانک یا خانه برو";
    }
    void ExitCar()
    {
        driving=false; player.transform.position=car.transform.position-car.transform.right*2.5f+Vector3.up*.2f;
        carSpeed=0; notice="از خودرو پیاده شدی";
    }
    void SaveGame()
    {
        PlayerPrefs.SetInt("cash",cash); PlayerPrefs.SetInt("bank",bank);
        PlayerPrefs.SetInt("house",houseOwned?1:0); PlayerPrefs.SetString("job",activeJob);
        if(player) { PlayerPrefs.SetFloat("px",player.transform.position.x); PlayerPrefs.SetFloat("pz",player.transform.position.z); }
        PlayerPrefs.Save();
    }
    void LoadGame()
    {
        cash=PlayerPrefs.GetInt("cash",2500); bank=PlayerPrefs.GetInt("bank",0);
        houseOwned=PlayerPrefs.GetInt("house",0)==1; activeJob=PlayerPrefs.GetString("job","");
    }
    void OnApplicationPause(bool pause) { if(pause) SaveGame(); }
    void OnApplicationQuit() { SaveGame(); }

    void OnGUI()
    {
        if(hud==null) hud=new GUIStyle(GUI.skin.label){fontSize=20,normal={textColor=Color.white}};
        GUI.Box(new Rect(12,12,Mathf.Min(340,Screen.width-24),112),"");
        GUI.Label(new Rect(24,18,310,30),"FreeLife RP",hud);
        GUI.Label(new Rect(24,48,310,26),"نقد: $"+cash+"   بانک: $"+bank,small);
        GUI.Label(new Rect(24,75,310,26),"شغل: "+(activeJob==""?"نداری":activeJob)+(houseOwned?" | خانه: داری":""),small);
        GUI.Label(new Rect(24,101,Screen.width-48,28),notice,small);
        float y=Screen.height-78;
        if(GUI.Button(new Rect(12,y,100,58),driving?"پیاده شو":"تعامل")) { if(driving) ExitCar(); else Interact(); }
        if(GUI.Button(new Rect(120,y,95,58),"شغل‌ها")) showJobs=!showJobs;
        if(GUI.Button(new Rect(223,y,95,58),"ذخیره")) { SaveGame(); notice="بازی ذخیره شد"; }
        if(showJobs)
        {
            GUI.Box(new Rect(12,140,Mathf.Min(300,Screen.width-24),240),"فهرست شغل‌ها");
            int n=0;
            foreach(var j in jobs)
            {
                if(GUI.Button(new Rect(24,172+n*38,Mathf.Min(270,Screen.width-48),34),j.Key+"  |  $"+j.Value))
                { activeJob=j.Key; showJobs=false; notice="شغل انتخاب شد؛ به محل کار زردرنگ برو"; SaveGame(); }
                n++;
            }
        }
        float cx=Screen.width-190, cy=Screen.height-255;
        if(GUI.RepeatButton(new Rect(cx+65,cy,60,58),"▲")) MoveTouch(Vector3.forward);
        if(GUI.RepeatButton(new Rect(cx+65,cy+124,60,58),"▼")) MoveTouch(Vector3.back);
        if(GUI.RepeatButton(new Rect(cx,cy+62,60,58),"◀")) MoveTouch(Vector3.left);
        if(GUI.RepeatButton(new Rect(cx+130,cy+62,60,58),"▶")) MoveTouch(Vector3.right);
        if(driving)
        {
            if(GUI.RepeatButton(new Rect(12,Screen.height-155,90,60),"گاز")) MoveCar(1);
            if(GUI.RepeatButton(new Rect(110,Screen.height-155,90,60),"ترمز")) MoveCar(-1);
        }
    }
    void MoveTouch(Vector3 dir)
    {
        if(driving) { car.transform.Rotate(0,dir.x*65f*Time.deltaTime,0); car.transform.position+=car.transform.forward*dir.z*7f*Time.deltaTime; }
        else { controller.Move(dir*4f*Time.deltaTime); if(dir.sqrMagnitude>.01f) player.transform.forward=dir; }
    }
    void MoveCar(float direction)
    {
        carSpeed=Mathf.MoveTowards(carSpeed,direction*10f,18f*Time.deltaTime);
        car.transform.position+=car.transform.forward*carSpeed*Time.deltaTime;
    }
}