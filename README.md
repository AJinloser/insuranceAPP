## insuranceAPP
### 技术栈
- 前端：Flutter(三端互通：IOS、Android、Web统一开发)
- 后端：python FastAPI
- 数据库：PostgreSQL
- 部署：Docker
- 包管理工具：uv

### 项目结构
```
insuranceApp/
├── backend/         # FastAPI后端服务
│   ├── app/         # 应用代码
│   │   ├── api/     # API路由
│   │   ├── core/    # 核心配置
│   │   ├── db/      # 数据库
│   │   │   ├── crud/      # CRUD操作
│   │   │   ├── importers/ # 数据导入器
│   │   │   └── ...
│   │   ├── models/  # 数据模型
│   │   └── schemas/ # 数据架构
│   ├── datas/       # 数据文件
│   │   ├── 基本医保.xlsx     # 基本医保数据文件
│   │   ├── 定期寿险.xlsx     # 定期寿险产品数据
│   │   ├── 非年金.xlsx       # 非年金产品数据
│   │   ├── 年金.xlsx         # 年金产品数据
│   │   ├── 医疗保险.xlsx     # 医疗保险产品数据
│   │   └── 重疾险.xlsx       # 重疾险产品数据
│   ├── tests/       # 测试
│   ├── Dockerfile   # Docker配置
│   ├── pyproject.toml # Python项目配置
│   └── requirements.txt # 依赖
└── frontend/        # Flutter前端
    ├── lib/         # 应用代码
    │   ├── models/  # 数据模型
    │   ├── pages/   # 页面
    │   ├── screens/ # 屏幕页面
    │   ├── services/# 服务
    │   ├── utils/   # 工具类
    │   └── widgets/ # UI组件
    ├── assets/      # 资源文件
    └── pubspec.yaml # Flutter项目配置
```

### 前端页面设计
- **登录页**
    - 具体参考![登录页设计](./Design/login_page.png)
    - 采用经典的基础页面设计
    - 顶部为logo,logo下方为账号、密码输入框；密码输入框有密码显示隐藏按钮
    - 输入框下方左侧有持久化勾选框，勾选后下次登录时无需再次输入账号密码
    - 输入框下方右侧有忘记密码按钮，点击转至忘记密码模式
        - 忘记密码模式包含logo、账号、新密码、重置密码按钮（暂时不添加验证信息）
    - 再下方为登录按钮（暂不支持通过其他方式登录）
    - 页面底部为没有账号时的注册按钮，点击转至注册模式
        - 注册模式同样包含logo、账号、密码、确认密码、注册按钮
        - 注册模式自动检测密码和确认密码是否一致，不一致时提示
    - 具有账号密码错误时的提示，输入框变为红色
    - 登录成功后转至首页
- **首页**
    - 首页可通过底部导航栏通过滑动或点击，切换聊天页面、保险页面、规划页面、个人信息页面；默认为对话页面

- **对话页面**
    - 对话页面的实现可以参考insuranceAPP/Financial-Planner项目的实现，转变为Flutter实现
        - Financial-Planner项目是基于typescript+react实现Dify前端项目，可以作为逻辑和结构参考
    - 对话页面由顶部栏、中间对话框、底部输入框组成
    - 如果是新对话
        - 此时对话框中展示该模块的基本信息，开场白、开场推荐问题列表、用户输入表单等
        - 可以通过DifyAPI:GET/parameters获取应用参数
    - 顶部栏包含当前对话标题（默认显示为“新对话”）、一个侧面按钮、一个新建对话按钮组成
        - 对话标题可以由用户重命名，该功能可以由Dify API:POST/conversations/:conversation_id/name实现
        - 需要注意的是，对话标题可以通过POST/conversations/:conversation_id/name中将auto_generate设置为true，由Dify API自动生成,也可以使用这个方法自动更新对话标题
        - 左上角一个菜单按钮，点击可以进入菜单页面
        - 右上角一个新建对话按钮可新建一个对话，并终止当前对话，重置聊天页面。
    - 中间对话框由经典的头像+对话气泡的方式组成
        - 气泡中的内容需要能够展示ai返回的markdown格式内容,并且支持流式地显示
            - 最好能够通过Dify对话消息API返回的workflow_started、node_started、node_finished、workflow_finished等事件，显示加载进度。
        - 需要能够展示用户上传的图片、文件信息等
        - 气泡应该有点赞、点踩、语音播放按钮
            - 点赞、点踩按钮可以由Dify API:POST/messages/:message_id/feedbacks实现
            - 语音播放可以通过Dify API:POST/text-to-audio实现
        - 需要能够通过滚动上滑加载历史消息：
            - 可以通过Dify API:GET/messages获取会话历史消息
    - 底部输入框包含输入框、一个语音输入按钮、一个上传文件按钮和一个发送按钮（在导航栏之上）。
        - 发送按钮通过调用Dify API:POST/chat-messages发送消息
        - 语音输入按钮通过调用Dify API:POST/audio-to-text实现
            - 语音输入按钮可采取长按按钮移至中心变为圆形开始录音，通过检测声音大小变动圆形的大小实现动画效果，实时转录的显示转录后的文字的实现方式
        - 上传文件按钮通过调用Dify API:POST/file-upload实现

- **菜单页面**
    - 菜单页面分为三个部分，纵向排列
    - 第一个部分为AI模块选择
        - 通过/ai_modules接口获取AI模块列表，
        - 然后使用获得的api key通过Dify API:GET/info获取应用信息(名称和描述)
        - 并通过横向卡片列表的方式展示ai模块的名称和描述。
    - 第二个部分为历史聊天记录
        - 通过纵向列表的方式展示历史聊天的名称和时间。
        - 可以通过dify API:GET/conversations获取会话历史列表
            - 需要注意的是，会话历史列表仅包含当前选择的AI模块的会话历史
            - 如果切换ai模块，会话历史列表也应该相应的切换！
        - 点击后可跳转至对应会话的对话页面继续聊天
        - 可以通过Dify API:DELETE/conversations/:conversation_id删除会话
    - 第三部分为右上角一个返回按钮，点击后可以返回对话页面

- **保险页面**
    - 保险产品页面分为三个部分，纵向排列
    - 第一部分为顶部导航栏
        - 通过GET /insurance_products/product_types获取保险产品类型列表，通过获取的列表设置顶部导航栏
        - 顶部导航栏用于切换保险产品种类（可以通过点击、滑动等方式切换）
        - 保险产品种类影响搜索时发送的product_type字段,进而影响后端搜索那个表
    - 第二部分为搜索栏
        - 搜索栏包含一个搜索框、一个搜索按钮、一个重置按钮以及一个下拉表单
        - 搜索框对应搜索的product_name字段
        - 下拉表单点击后显示一个大的表格，包含许多表项，每个表项对应每个保险产品种类的可选字段，可以进行筛选，也可以为空（每个保险产品不同）
            - 可以通过GET /insurance_products/product_fields获取保险产品类型对应字段列表
        - 搜索按钮和重置按钮分别对应搜索和重置，重置按钮清空搜索框和下拉表单
    - 第三部分为保险产品列表
        - 保险产品以卡片的形式展示，卡片包含产品名称、公司名称、保险类型、保费、总评分这些基本信息
        - 卡片右端有查看详情按钮，点击后转至具体保险产品信息页面
        - 卡片列表末尾有页码，可以通过点击页码或点击页码左右两端的切换页按钮来切换页，切换页会向后端请求对应页的保险产品列表
        - 卡片列表的右上角有排序按钮，用类似下拉表单的方式，点击后可以选择按照什么字段排序（会重新向后端请求数据）
    - 保单相关部分
        - 在卡片列表下方，添加一个淡紫色的卡片为‘我的保单’，点击后转至用户保单页面
    - **新添加的chat相关部分**：
        - 在‘我的保单’上方，卡片列表页码下方，添加一个‘产品对比’卡片，卡片包含两个中间带有‘加号’的方框，方框下方有‘产品对比’按钮。
        - 对保险卡片添加一个右键点击事件，点击后弹出菜单，菜单包含‘进行对比’按钮，点击后该产品加入到‘产品对比’卡片中，在‘产品对比’卡片中可以进行删除。
        - 点击‘产品对比’按钮后，首先根据.env中的CHAT_COMPARE_KEY给出的api key,在chat页面中的ai模块列表中找到对应的ai模块，跳转到对应的对话页面进行对话（如果没有找到，则提示用户没有找到对应的ai模块）
        - 复用已经实现的对话页面，不需要重新创建
        - 跳转页面并通过Dify API:POST/chat-messages发送第一条对话信息，具体要求
            - 在对话信息中，query字段为"你好，我想对比这两个保险产品"
            - 在对话信息中，通过GET /insurance_products/product_info获取两个具体的保险产品信息（还需添加product_type字段），并把这个信息作为inputs字段中的text字段，即inputs字段为{"text": "具体的保险产品信息"}
        - 后续的对话过程与原先对话一致。

- **用户保单页面**
    - 用户保单页面包含一个顶部栏，顶部栏左侧为返回按钮，用于返回保险页面。
    - 进入用户保单页面后，通过 GET /insurance_list/get 获取用户保单信息
    - 再通过获得到的用户保单信息，通过GET /insurance_products/product_info获取每个保险产品的详细信息
    - 使用保险产品卡片的形式，用卡片列表展示用户保单中的保险产品，卡片形式与保险产品列表页面中的卡片形式一致
    - 顶部栏下方，卡片列表右上方有一个修改按钮，点击后可以进入修改模式
        - 进入修改模式后，所有卡片可勾选
        - 修改模式中，页面底部包含一个删除按钮
        - 勾选后，可以点击点击删除按钮，删除勾选的保险产品
        - 通过POST /insurance_list/update更新用户保单信息表中的对应字段
    - **新添加的chat相关部分**：
        - 在用户保单底部添加一个‘保单分析’按钮。
        - 点击‘保单分析’按钮后，首先根据.env中的CHAT_WITH_INSURANCE_LIST_KEY给出的api key,在chat页面中的ai模块列表中找到对应的ai模块，跳转到对应的对话页面进行对话（如果没有找到，则提示用户没有找到对应的ai模块）
        - 复用已经实现的对话页面，不需要重新创建
        - 跳转页面并通过Dify API:POST/chat-messages发送第一条对话信息，具体要求
            - 在对话信息中，query字段为"你好，我想分析保单"
            - 在对话信息中，通过GET /insurance_products/product_info获取用户保单中所有保险产品的具体的保险产品信息（还需添加product_type字段），并把这个信息作为inputs字段中的text字段，即inputs字段为{"text": "具体的保险产品信息"}
        - 后续的对话过程与原先对话一致。

    

- **具体保险产品信息页面**
    - 点击查看详情后进入，使用对应保险产品id通过GET /insurance_products/product_info获取具体保险产品信息
    - 根据不同的保险产品类型展示不同的信息，具体由~/insuranceApp/backend/sql/表说明.md中的表结构决定
    - 页面左上角需要包含一个返回按钮，点击后返回保险产品列表页面
    - 在保险产品信息页面的底部，添加一个添加保单按钮，点击后调用POST /insurance_list/add将保险产品信息添加到用户保单信息表中
    - **新添加chat相关部分**：在添加保单按钮的下方，添加一个"与保险产品对话“按钮。
        - 点击后，首先根据.env中的CHAT_WITH_INSURANCE_KEY给出的api key,在chat页面中的ai模块列表中找到对应的ai模块，跳转到对应的对话页面进行对话（如果没有找到，则提示用户没有找到对应的ai模块）
        - 复用已经实现的对话页面，不需要重新创建
        - 跳转页面并通过Dify API:POST/chat-messages发送第一条对话信息，具体要求
            - 在对话信息中，query字段为"你好，我想了解这个保险产品"
            - 在对话信息中，通过GET /insurance_products/product_info获取具体的保险产品信息（还需添加product_type字段），并把这个信息作为inputs字段中的text字段，即inputs字段为{"text": "具体的保险产品信息"}
        - 后续的对话过程与原先对话一致。



- **个人中心页面**
    - 个人中心页面目前只需展示用户个人信息
    - ui风格与当前app的其他页面一致
    - 个人中心页面包含一个顶部栏，一个用户个人信息卡片
    - 点击用户个人信息卡片后，可以进入**用户个人信息编辑页面**
        - 用户个人信息编辑页面包含一个顶部栏，顶部栏左上角有一个返回按钮，用于返回个人中心页面
        - 进入用户个人中心页面后，通过GET /user_info获取用户个人信息
        - 将获取到的用户个人信息用合适的方式展示，个人信息格式具体可参考后端数据库中用户个人信息表的表结构
        - 展示ui风格与当前app的其他页面一致，可以适当使用卡片的形式
        - 用户可以通过直接点击对应字段进行编辑（点击后，字段变为输入框，用户可以输入内容）
            - 对于family_info中的family_members，可以点击添加或删除按钮，添加或删除一个家庭成员
            - 对于goal_info中的goals，可以点击添加或删除按钮，添加或删除一个目标
        - 用户个人信息编辑页面底部包含一个保存按钮，点击后，通过API POST /user_info更新用户个人信息

- **个人信息初始化页面**
    - 个人信息初始化页面仅在新用户成功注册后进入，用户正常登录或保持登录不会进入该页面
    - 个人信息初始化的功能是，用亲和性和引导性强的方式，引导新用户填写一些个人信息包括基本信息、财务信息和目标信息，来初始化用户个人信息表
    - 个人信息初始化页面设计
        - ui风格与登录页面类似，不需要填满整个页面，而是使用卡片的形式
        - 卡片包含一个logo，若干输入框，总共分为三页，卡片底部有页码显示和上下页切换按钮，最后一页末尾有提交按钮
        - 第一页包含基本信息输入框，包括年龄、性别、城市
        - 第二页包含财务信息输入框，包括职业、收入、支出、资产、负债
        - 第三页包含目标信息输入框，包括目标、目标详情
        - 每一页的logo下方，输入框上方需要包含恰当的提示语，提示语需要能够引导用户填写个人信息，以下提示语仅供参考，可以适当修改
            - 第一页的提示语为：欢迎来到skysail，请您提供一些您的基本信息如年龄和性别，这能帮助我们更好地了解您来为您提供服务，如您担心隐私泄露，也可以不进行填写
            - 第二页的提示语为：请您提供一些您的财务信息，您可以回忆您的工作状况、生活支出和目前拥有的资产和负债，进行填写，这能帮助我们更好地了解您的财务状况
            - 第三页的提示语为：您目前最关心的问题是什么？最想要达成的目标是什么？例如：存下100万元提前退休，或是为养老做准备，您可以填写这部分信息，我们能够根据您的目标为您提供更加个性化的服务
        - 以上字段均可以留空，留空则提交空值，即''。
        - 提交按钮点击后，通过API POST /user_info更新用户个人信息
        - 提交按钮点击后，转至个人中心页面


- **规划页面**
    - 规划页面包含一个顶部导航栏，能够在“目标”、“日程”、“规划”三个选项之间切换
    - 先实现“目标”选项，“日程”和“规划”选项暂时不实现
    - **目标**
        - 目标页面目前由目标卡片列表构成，通过GET /goals/get_basic_info获取目标基本信息，然后通过目标卡片列表展示目标基本信息
        - 能够通过POST /goals/update_basic_info进行新增目标，删除目标，编辑目标
        - 目标卡片能够展示信息，包括：目标名称、目标描述、优先级、预计完成时间、目标金额、已完成金额即目标进度条
        - 每个目标下有子目标和任务，目标卡片要能展示子目标和任务的个数
        - 目标卡片需要展示子目标，包括子目标名称、子目标金额
        - 点击目标卡片后，能够进入目标详情页面
        - **目标详情页面**
            - 目标详情页面包含一个顶部导航栏，能够返回目标页面
            - 目标详情页面能够通过GET /goals/get_detail_info获取目标的详细信息，然后展示目标的详细信息
            - 目标详情页面能够通过GET /goals/get_detail_info获取目标的详细信息，然后展示目标的详细信息
            - 目标详情页面能够通过POST /goals/update_sub_goal展示并编辑子目标，对子目标进行新增、删除、编辑，编辑能够修改子目标的名称、描述、金额、预计完成时间等。
                - 其中完成状态可以利用checkbox来表示，如果完成的话，checkbox被勾选，否则未勾选
                - 预计完成时间可以利用日期选择器来表示，用户选择日期后，会自动转换为YYYY-MM-DD格式
            - 目标详情页面能够通过POST /goals/update_sub_task展示并编辑任务，对任务进行标记完成操作（如果完成的话需要改变任务的状态），或者新增、删除、编辑。
                - 其中完成状态可以利用checkbox来表示，如果完成的话，checkbox被勾选，否则未勾选
                - 预计完成时间可以利用日期选择器来表示，用户选择日期后，会自动转换为YYYY-MM-DD格式
    - **日程**
        - 日程页面包含一个日历，能够选择日期（默认选择当前日期）
        - 点击对应日期后，能够通过GET /goals/get_by_date获取对应日期的目标、子目标、子任务信息，然后通过卡片列表展示当前日期下目标、子目标、子任务信息
        - 卡片列表仅需展示类型为目标/子目标/子任务，以及对应名称和对应金额，其中目标还需展示已完成金额/目标金额的进度条，子任务还需通过checkbox来表示完成状态
        - 对于每个目标/子目标/子任务，能够通过右滑后点击修改日期按钮，通过POST /goals/update_date修改对应目标/子目标/子任务的预计完成时间（需要传入goal_id,sub_goal_id/sub_task_id,所以前端需要在GET /goals/get_by_date储存对应的id），修改日期后，卡片列表会自动更新
        - 对于子任务，可以通过点击checkbox来，调用POST /goals/update_sub_task_status更新子任务状态，更新后，卡片列表会自动更新（如果对应父目标在当前日期下，则目标的已完成金额会自动更新）
    - **规划**
        - 规划页面包含一个环状图和一个折线图，用于展示用户目标规划的整体情况
        - 环状图
            - 通过GET /goals/get_basic_info获取用户目标的金额，然后通过不同颜色的图示展示用户不同目标，环状图的每个部分代表一个目标，每个部分的颜色代表一个目标，每个部分的大小代表一个目标的金额。
            - 环状图的每一个部分能够点击，点击后这一部分进一步细分为子目标，使用不同颜色展示子目标，细分后每个部分的大小代表一个子目标的金额（如果子目标的金额总和不等于父目标，则剩下的金额用灰色表示，代表未分配的金额）
        - 折线图
            - 折线图的x轴为时间，y轴为金额
            - 折线图有两条线，分别为虚线和实线，虚线代表用户预计完成的金额，实线代表用户实际完成的金额
            - 初始状态时，时间默认为最近一周，通过GET /goals/get_by_date获取最近一周预计完成的金额（目标和子目标的金额不计入，只计入子任务的金额，因为目标和子目标只具备标识作用，而不代表实际操作），并通过子任务其中任务状态为完成的任务的金额来计算实际完成的金额
            - 折线图的x轴可以切换为最近一个月以及最近一年，切换后，折线图会自动更新，更新后，折线图的x轴会自动切换为对应的时间，并更新折线图的y轴为对应的时间的预计完成的金额和实际完成的金额

        

    
### 后端API
- 登录API
    - 请求方式：POST
    - 请求路径：/login
    - 请求参数：
        - account: 账号
        - password: 密码
    - 后端根据账号密码判断是否登录成功
    - 返回体：
        - code:状态码
        - token: JWT token
        - user_id: 用户ID
        - message: 登录成功或失败信息
    - 登录成功后，将token和user_id返回给前端
    - 登录失败后，返回错误信息
- 注册API
    - 请求方式：POST
    - 请求路径：/register
    - 请求参数：
        - account: 账号
        - password: 密码
    - 后端将账号和密码储存到数据库中,并使用账号为用户生成user_id
    - 返回体：
        - code:状态码
        - message: 注册成功或失败信息
        - token: JWT token
        - user_id: 用户ID
- 忘记密码API
    - 请求方式：POST
    - 请求路径：/reset_password
    - 请求参数：
        - account: 账号
        - new_password: 新密码
    - 后端根据账号和新密码更新数据库中密码
    - 返回体：
        - code:状态码
        - message: 重置密码成功或失败信息
        - token: JWT token
        - user_id: 用户ID

- 获取AI模块列表API
    - 请求方式：GET
    - 请求路径：/ai_modules
    - 请求参数：
        - user_id: 用户ID
    - 后端根据用户ID获取AI模块列表
    - 返回体：
        - code:状态码
        - message: 获取AI模块列表成功或失败信息
        - ai_modules: AI模块API key列表
    - AI key列表可以设置在.env文件中

- 对话和聊天相关的API
    - **请注意**：本后端不需要实现对话和聊天的API，前端直接调用Dify提供的API即可。



- 获取保险产品类型API
    - 请求方式：GET
    - 请求路径：/insurance_products/product_types
    - 请求参数：无
    - 返回体：
        - code:状态码
        - message: 获取保险产品类型成功或失败信息
        - product_types: 保险产品类型列表（包含：term_life（定期寿险）、non_annuity（非年金）、annuity（年金）、medical（医疗保险）、critical_illness（重疾险））

- 获取保险产品类型对应字段API
    - 请求方式：GET
    - 请求路径：/insurance_products/product_fields
    - 请求参数：
        - product_type: 产品类型（表名后缀，如term_life、medical等）
    - 返回体：
        - code:状态码
        - message: 获取保险产品类型对应字段成功或失败信息
        - fields: 保险产品类型对应字段列表，每个字段包含：
            - name: 字段名（英文）
            - type: 数据类型
            - description: 字段说明（中文）


- 保险产品搜索API
    - 请求方式：GET
    - 请求路径：/insurance_products/search
    - 请求参数：
        - product_type: 产品类型（必填，表名后缀）
        - page: 页码（必填，默认1）
        - limit: 每页条数（必填，默认10）
        - sort_by: 排序字段（可选，为空则按数据库默认顺序）
        - sort_order: 排序方向（可选，asc或desc，默认desc）
        - 其他可选筛选参数：根据不同产品类型有不同的字段可用于筛选
            - 数值类型字段：支持精确匹配或范围筛选（使用字段名_min和字段名_max）
            - BOOLEAN类型字段：支持是/否筛选
            - 文本类型字段：支持模糊匹配
    - 返回体：
        - code: 状态码
        - message: 搜索成功或失败信息
        - pages: 总页数
        - products: 保险产品列表（使用中文字段名返回，包含该产品类型的所有字段）
    
- 具体保险产品信息查询API
    - 请求方式：GET
    - 请求路径：/insurance_products/product_info
    - 请求参数：
        - product_id: 产品ID
        - product_type: 产品类型（表名后缀）
    - 返回体：
        - code: 状态码
        - message: 查询成功或失败信息
        - product_type: 产品类型
        - 产品详细信息（使用中文字段名返回，包含该产品的所有字段）

- 获取用户个人信息API
    - 请求方式：GET
    - 请求路径：/user_info
    - 请求参数：
        - user_id: 用户ID
    - 返回体：
        - code:状态码
        - message: 获取用户个人信息成功或失败信息
        - user_info: 用户个人信息（包含数据库中用户基本信息表的全部字段）
            - basic_info: 用户基本信息
            - financial_info: 用户财务信息
            - risk_info: 用户风险偏好信息
            - retirement_info: 用户退休信息
            - family_info: 用户家庭信息
            - goal_info: 用户目标信息
            - other_info: 其他信息

- 更新用户个人信息API
    - 请求方式：POST
    - 请求路径：/user_info
    - 请求参数：
        - user_id: 用户ID
        - user_info: 用户个人信息（包含数据库中用户个人信息表的全部字段）
        - 后端根据user_id和传回来的user_info更新数据库中用户个人信息表的对应字段
    - 返回体：
        - code:状态码
        - message: 更新用户个人信息成功或失败信息


- 获取用户保单信息API
    - 请求方式：GET
    - 请求路径： /insurance_list/get
    - 请求参数：
        - user_id: 用户ID
    - 返回体：
        - code:状态码
        - message: 获取用户保单信息成功或失败信息
        - insurance_list: 用户保单信息列表,每个列表元素为一个包含product_id和product_type的jsonb对象

- 添加保险产品进入保单API
    - 请求方式：POST
    - 请求路径：/insurance_list/add
    - 请求参数：
        - user_id: 用户ID
        - product_id: 产品ID
        - product_type: 产品类型
    - 后端根据user_id和product_id、product_type将保险产品信息添加到用户保单信息表中

- 更新用户保单API
    - 请求方式：POST
    - 请求路径：/insurance_list/update
    - 请求参数：
        - user_id: 用户ID
        - insurance_list: 用户保单信息列表,每个列表元素为一个包含product_id和product_type的jsonb对象
    - 后端根据user_id和传回来的insurance_list更新用户保单信息表中的对应字段

- 获取目标基本信息API
    - 请求方式：GET
    - 请求路径：/goals/get_basic_info
    - 请求参数：
        - user_id: 用户ID
    - 返回体：
        - code:状态码
        - message: 获取目标基本信息成功或失败信息
        - goals: 目标列表
            - goal_id: 目标ID
            - goal_name: 目标名称
            - goal_description: 目标描述
            - priority: 优先级
            - expected_completion_time: 预计完成时间
            - target_amount: 目标金额
            - completed_amount: 已完成金额
            - sub_goals: 子目标列表
                - sub_goal_id: 子目标ID
                - sub_goal_name: 子目标名称
                - sub_goal_amount: 子目标金额
            - sub_task_num: 子任务总个数
            - sub_task_completed_num: 子任务已完成个数

- 更新目标基本信息API
    - 请求方式：POST
    - 请求路径：/goals/update_basic_info
    - 请求参数：
        - user_id: 用户ID
        - goals: 目标列表
            - goal_id: 目标ID
            - goal_name: 目标名称
            - goal_description: 目标描述
            - priority: 优先级
            - expected_completion_time: 预计完成时间
            - target_amount: 目标金额
            - completed_amount: 已完成金额
            - 新建的目标默认子目标和子任务为空，而这个API不能编辑子目标和子任务，只能编辑目标的基本信息
        - 后端根据user_id和传回来的goals更新数据库中目标表中的对应字段

- 获取目标详细信息API
    - 请求方式：GET
    - 请求路径：/goals/get_detail_info
    - 请求参数：
        - user_id: 用户ID
        - goal_id: 目标ID
    - 返回体：
        - code:状态码
        - message: 获取目标详细信息成功或失败信息
        - goal_detail: 目标详细信息
            - goal_id: 目标ID
            - goal_name: 目标名称
            - goal_description: 目标描述
            - priority: 优先级
            - expected_completion_time: 预计完成时间
            - target_amount: 目标金额
            - completed_amount: 已完成金额
            - sub_goals: 子目标列表
                - sub_goal_id: 子目标ID
                - sub_goal_name: 子目标名称
                - sub_goal_description: 子目标描述
                - sub_goal_amount: 子目标金额
                - sub_goal_completion_time: 子目标预计完成时间
                - sub_goal_status: 子目标状态
            - sub_tasks: 子任务列表
                - sub_task_id: 子任务ID
                - sub_task_name: 子任务名称
                - sub_task_description: 子任务描述
                - sub_task_status: 子任务状态
                - sub_task_completion_time: 子任务预计完成时间
                - sub_task_amount: 子任务金额

- 更新子目标API
    - 请求方式：POST
    - 请求路径：/goals/update_sub_goal
    - 请求参数：
        - user_id: 用户ID
        - goal_id: 目标ID
        - sub_goals: 子目标列表
            - sub_goal_id: 子目标ID
            - sub_goal_name: 子目标名称
            - sub_goal_description: 子目标描述
            - sub_goal_amount: 子目标金额
            - sub_goal_completion_time: 子目标预计完成时间
            - sub_goal_status: 子目标状态
        - 后端根据user_id和传回来的sub_goals更新数据库中目标表中的对应字段,能够新增子目标，删除子目标，编辑子目标

- 更新子任务API
    - 请求方式：POST
    - 请求路径：/goals/update_sub_task
    - 请求参数：
        - user_id: 用户ID
        - goal_id: 目标ID
        - sub_tasks: 子任务列表
            - sub_task_id: 子任务ID
            - sub_task_name: 子任务名称
            - sub_task_description: 子任务描述
            - sub_task_status: 子任务状态
            - sub_task_completion_time: 子任务预计完成时间
            - sub_task_amount: 子任务金额
        - 后端根据user_id和传回来的sub_tasks更新数据库中目标表中的对应字段,能够新增子任务，删除子任务，编辑子任务
        - 当子任务状态标记为完成时，需要对应的更新子任务的父目标的已完成金额，即增加父目标已完成金额的子任务金额对应的值

- 通过日程时间获取目标、子目标、子任务API
    - 请求方式：GET
    - 请求路径：/goals/get_by_date
    - 请求参数：
        - user_id: 用户ID
        - date: 日程时间
    - 返回体：
        - code:状态码
        - message: 通过日程时间获取目标、子目标、子任务成功或失败信息
        - goals: 目标列表
            - goal_id: 目标ID
            - goal_name: 目标名称
            - target_amount: 目标金额
            - completed_amount: 已完成金额
            - sub_goals: 子目标列表
                - sub_goal_id: 子目标ID
                - sub_goal_name: 子目标名称
                - sub_goal_amount: 子目标金额
            - sub_tasks: 子任务列表
                - sub_task_id: 子任务ID
                - sub_task_name: 子任务名称
                - sub_task_status: 子任务状态
                - sub_task_amount: 子任务金额
    - 后端根据user_id和date获取目标、子目标、子任务信息，并返回给前端

- 通过id修改时间API
    - 请求方式：POST
    - 请求路径：/goals/update_date
    - 请求参数：
        - user_id: 用户ID
        - type: 类型，goal_id或者sub_goal_id或者sub_task_id
        - goal_id: 目标ID(子目标或子任务的父目标的id)
        - sub_goal_id/sub_task_id: 子目标ID/子任务ID/none
        - date: 时间
    - 后端根据user_id和type、goal_id、sub_goal_id/sub_task_id、date更新数据库中目标表中的对应字段
    - 返回体：
        - code:状态码
        - message: 通过id修改时间成功或失败信息

- 通过id更新子任务状态API
    - 请求方式：POST
    - 请求路径：/goals/update_sub_task_status
    - 请求参数：
        - user_id: 用户ID
        - goal_id: 目标ID(子任务的父目标的id)
        - sub_task_id: 子任务ID
        - sub_task_status: 子任务状态
    - 后端根据user_id和sub_task_id更新数据库中目标表中的对应字段
    - 注意：
        - 如果子任务状态为从未完成变为完成，则需要更新子任务的父目标的已完成金额，即增加父目标已完成金额的子任务金额对应的值
        - 如果子任务状态为从完成变为未完成，则需要减少父目标已完成金额的子任务金额对应的值
    - 返回体：
        - code:状态码
        - message: 通过id更新子任务状态成功或失败信息

- 基本医保查询API
    - 请求方式：GET
    - 请求路径：/basic_medical_insurance/query
    - 请求参数：
        - city: 城市名称
        - category: 种类（城镇职工/城乡居民）
        - employment_status: 在职/退休状态（仅在种类为城镇职工时有效，可选）
    - 后端根据城市匹配基本医保表中的城市字段，然后根据种类和在职/退休状态过滤相关字段
    - 返回体：
        - code: 状态码
        - message: 查询成功或失败信息
        - data: 过滤后的基本医保数据（中文字段名）

- 获取基本医保城市列表API
    - 请求方式：GET
    - 请求路径：/basic_medical_insurance/cities
    - 返回体：
        - code: 状态码
        - message: 获取城市列表成功或失败信息
        - cities: 城市名称列表
        - count: 城市数量

### 后端数据库
- 目前先采用postgresql数据库
- 数据库表结构
    - 用户表
        - user_id: 用户ID
        - account: 账号
        - password: 密码

    - 保险产品表（从xlsx文件导入）
        - 保险产品数据存储在~/insuranceApp/backend/datas/目录下的xlsx文件中
        - 包含5个产品类型表：
            - insurance_products_term_life: 定期寿险表
            - insurance_products_non_annuity: 非年金表
            - insurance_products_annuity: 年金表
            - insurance_products_medical: 医疗保险表
            - insurance_products_critical_illness: 重疾险表
        - 每个表的字段结构由对应xlsx文件的前三列定义：
            - A列：字段名（英文）
            - B列：字段说明（中文）
            - C列：数据类型
        - 所有表都包含product_id作为主键
        - 数据从xlsx文件的D列开始，每列代表一个产品

    - 用户个人信息表（用于存储用户个人信息）
        所有字段都为jsonb类型,并且具体内容使用字符串存储
        - basic_info: 用户基本信息
            - age:年龄
            - city:城市
            - gender:性别
            - health_status: 健康状况(新增字段)
        - financial_info: 用户财务信息
            - occupation: 职业
            - income: 收入
            - expenses: 支出
            - assets: 资产
            - liabilities: 负债
            - current_assets: 流动资产（新增字段）
        - risk_info:
            - risk_aversion: 风险厌恶程度
        - retirement_info: 退休信息
            - retirement_age: 退休年龄
            - retirement_income: 退休收入
        - insurance_info: 保险信息
            - social_medical_insurance: 社会医疗保险(新增字段)
            - social_endowment_insurance: 社会养老保险(新增字段)
            - business_insurance: 商业保险(新增字段)
        - family_info: 家庭信息（可以有多个家庭成员）
            - family_members: 家庭成员列表
                - relation: 关系
                - age: 年龄
                - occupation: 职业
                - income: 收入
        - goal_info: 目标(可以有多个目标)
            - goals: 目标列表
                - goal_details: 目标详情
        - other_info: 其他信息

    - 用户保单信息表（用于存储用户保单信息）
        - insurance_list:储存用户拥有的保险产品信息，为列表，每个列表元素为一个包含product_id和product_type的jsonb对象


    - 目标表（用于存储用户目标信息）
        - goals: 目标列表
            - 每个目标包含下列信息
            - goal_id: 目标ID
            - goal_name: 目标名称
            - goal_description: 目标描述
            - priority: 优先级
            - expected_completion_time: 预计完成时间（格式为YYYY-MM-DD）
            - target_amount: 目标金额
            - completed_amount: 已完成金额
            - sub_goals: 子目标列表
                - sub_goal_id: 子目标ID
                - sub_goal_name: 子目标名称
                - sub_goal_description: 子目标描述
                - sub_goal_amount: 子目标金额
                - sub_goal_completion_time: 子目标预计完成时间（格式为YYYY-MM-DD）
                - sub_goal_status: 子目标状态（表明是否完成）
            - sub_tasks: 子任务列表
                - sub_task_id: 子任务ID
                - sub_task_name: 子任务名称
                - sub_task_description: 子任务描述
                - sub_task_status: 子任务状态（表明是否完成）
                - sub_task_completion_time: 子任务预计完成时间（格式为YYYY-MM-DD）
                - sub_task_amount: 子任务金额

    - 基本医保表（用于存储各城市基本医保政策信息）
        - id: 主键ID
        - city: 城市名称（索引字段）
        - data_year: 数据年份
        - coordination_level: 统筹层次
        - official_website: 官网链接
        - policy_document_number: 政策文件号
        - 职工相关字段：
            - employee_contribution_base_lower: 职工_缴费基数下限
            - employee_contribution_base_upper: 职工_缴费基数上限
            - employee_unit_contribution_rate: 职工_单位缴费比例
            - employee_personal_contribution_rate: 职工_个人缴费比例
        - 居民相关字段：
            - resident_personal_contribution_standard: 居民_个人缴费标准
            - resident_financial_subsidy_standard: 居民_财政补助标准
        - 在职相关字段：
            - active_employee_account_transfer_rate: 在职_职工划入比例
            - active_outpatient_payment_ratio: 在职_门诊支付比例
            - active_segment1-4相关字段: 在职分段支付比例
        - 退休相关字段：
            - retired_employee_account_fixed_amount: 退休_职工划入定额
            - retired_outpatient_payment_ratio: 退休_门诊支付比例
            - retired_segment1-4相关字段: 退休分段支付比例
        - 其他政策字段：包括大病保险、异地就医、长期护理保险等相关字段